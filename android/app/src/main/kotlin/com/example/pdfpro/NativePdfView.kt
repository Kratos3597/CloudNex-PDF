package com.cloudnex.pdfpro

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.pdf.PdfRenderer
import android.os.ParcelFileDescriptor
import android.view.SurfaceHolder
import android.view.SurfaceView
import android.view.View
import io.flutter.plugin.platform.PlatformView
import java.io.File
import java.io.FileOutputStream

class NativePdfView(context: Context, id: Int, creationParams: Map<String?, Any?>?) : PlatformView {
    private val surfaceView: SurfaceView = SurfaceView(context)
    private var pdfRenderer: PdfRenderer? = null
    private var currentBitmap: Bitmap? = null
    private var currentPageIndex: Int = 0

    init {
        val filePath = creationParams?.get("filePath") as? String
        if (filePath != null) {
            openRenderer(File(filePath))
        }

        surfaceView.holder.addCallback(object : SurfaceHolder.Callback {
            override fun surfaceCreated(holder: SurfaceHolder) {
                renderCurrentPage()
            }
            override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {}
            override fun surfaceDestroyed(holder: SurfaceHolder) {}
        })
    }

    override fun getView(): View = surfaceView

    override fun dispose() {
        pdfRenderer?.close()
        currentBitmap?.recycle()
    }

    private fun openRenderer(file: File) {
        val fileDescriptor = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
        pdfRenderer = PdfRenderer(fileDescriptor)
    }

    private fun renderCurrentPage() {
        val renderer = pdfRenderer ?: return
        if (renderer.pageCount <= currentPageIndex) return

        val page = renderer.openPage(currentPageIndex)
        
        // Calculate dimensions for S25 Ultra high-res output
        val width = surfaceView.width
        val height = (page.height.toFloat() / page.width.toFloat() * width).toInt()

        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
        
        val canvas = surfaceView.holder.lockCanvas()
        if (canvas != null) {
            canvas.drawColor(Color.WHITE)
            canvas.drawBitmap(bitmap, 0f, 0f, null)
            surfaceView.holder.unlockCanvasAndPost(canvas)
        }

        currentBitmap = bitmap
        page.close()
    }
}
