# Image library implements function that allow 

Surface = require './surface'

module.exports = 
  # load image from url and then call the callback function
  load: (url, callback)->
    image = new Image
    image.crossOrigin = "Anonymous"
    image.onload = (event)->
      canvas = document.createElement("canvas")
      canvas.width = image.width
      canvas.height = image.height
      context = canvas.getContext "2d"
      context.drawImage image, 0, 0
      imageData = context.getImageData 0, 0, image.width, image.height
      callback imageData
      null
    image.src = url
    null

  extract: (image)->
    array = new Float32Array(image.width * image.height * 4)
    width = image.width
    height = image.height
    stribe = width * 2
    halfpage = height * stribe
    Surface.extract array, image.data, 
      width, halfpage, width+halfpage, 
      height, stribe, width, 1
    while width >= 1 and height >= 1
      Surface.downsize array, array,
        height, stribe, width, 1
      width >>= 1; height >>= 1
    array

  compact: (array, context, width, height)->
    image = context.createImageData width, height
    size = width * height
    Surface.compact image.data, array, 
      width, size*2, width+size*2, 
      height, width*2, width, 1
    image

  flatten: (array, context, width, height)->
    image = context.createImageData width*2, height*2
    size = width * height
    Surface.flatten image.data, array, 
      height*2, width*2, width*2, 1
    image
