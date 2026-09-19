.pragma library

// Canvas fillText reshapes and outlines every label. Dense boards reuse a small
// vocabulary of rounded numbers, so retain rasterized labels with a byte limit.
// Render at 2x resolution to keep fractional board positions smooth.
function create(scratch, width, height, maxBytes) {
    var entries = new Map()
    var bytes = 0
    var budget = maxBytes === undefined ? 8 * 1024 * 1024 : maxBytes
    var scale = 2
    return {
        draw: function(ctx, text, x, y, font, color, fontSize) {
            var key = font + "\n" + color + "\n" + text
            var entry = entries.get(key)
            if (entry) {
                entries.delete(key)
                entries.set(key, entry)
            } else {
                scratch.font = font
                var imageWidth = Math.ceil(scratch.measureText(text).width) + 4
                var imageHeight = fontSize * 2 + 4
                var imageBytes = imageWidth * imageHeight * scale * scale * 4
                // Unusually large custom fonts use the normal vector path.
                if (imageWidth * scale > width || imageHeight * scale > height
                        || imageBytes > budget)
                    return false
                scratch.resetTransform()
                scratch.clearRect(0, 0, width, height)
                scratch.scale(scale, scale)
                scratch.fillStyle = color
                scratch.textAlign = "center"
                scratch.textBaseline = "middle"
                scratch.fillText(text, imageWidth / 2, imageHeight / 2)
                entry = {
                    "image": scratch.getImageData(0, 0, imageWidth * scale, imageHeight * scale),
                    "width": imageWidth, "height": imageHeight, "bytes": imageBytes
                }
                while (entries.size && bytes + imageBytes > budget) {
                    var oldest = entries.keys().next().value
                    bytes -= entries.get(oldest).bytes
                    entries.delete(oldest)
                }
                entries.set(key, entry)
                bytes += imageBytes
            }
            ctx.drawImage(entry.image, x - entry.width / 2, y - entry.height / 2,
                          entry.width, entry.height)
            return true
        }
    }
}
