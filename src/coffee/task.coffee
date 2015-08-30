Surface = require './surface'
Measure = require './measure'
Extreme = require './extreme'
Feature = require './feature'

colorList = [0..5]

module.exports =

  # convolute
  # --
  # Convolute a Float32Array object with a Float32Array kernel both lengthwise and crosswise.
  # Return a new Float32Array with result. For more detail, see Surface.convolute().

  convolute: (kernel, image, width, height)->
    count1 = height*2
    count0 = width*2
    radius = kernel.length>>1
    image0 = image
    image1 = new Float32Array(image.length)
    image2 = new Float32Array(image.length)

    Surface.convolute image1, image0, kernel,
      count1-radius*2, count0, count0, 1, kernel.length, count0
    Surface.convolute image2.subarray((count0+1)*radius), image1, kernel,
      count1-radius*2, count0, count0-radius*2, 1, kernel.length, 1

    image2


  # feature
  # --
  # Retrieve feature points from an Float32Array sandwidth slice of an filter pyramid.
  
  feature: (method, imageList, kernelList, sigmaList, width, height)->
    count1 = height*2
    count0 = width*2
    levelList = [0..imageList.length-2]
    levelAndCapList = [0..imageList.length-1]
    size = imageList[0].length

    #### measure
    # Use the specified 
    measureList = (new Float32Array(size) for level in levelAndCapList)
    for level in levelAndCapList
      measure = measureList[level]
      image = imageList[level]
      sigma = sigmaList[level]
      Measure[method] measure, image, sigma, count1, count0, count0, 1

    #### non-extremum suppression
    extremeList = ((new Int32Array(size>>4) for color in [0..5]) for level in levelList)
    extremeCountList = ((0 for color in colorList) for level in levelList)
    extremeCountTotal = (0 for color in colorList)
    for level in [1..levels]
      measure0 = measureList[level-1]
      measure1 = measureList[level]
      measure2 = measureList[level+1]
      extreme  = extremeList[level]
      border   = (kernelList[level].length>>1)+1
      count    = Extreme.neighbor_6 extreme, measure0, measure1, measure2, 
                                    border, count1, count0, count0, 1
      for color in colorList
        extremeCountList[level][color] = count[color]
        extremeCountTotal[color] += count[color]

    #### describe
    featureList = (new Float32Array(extremeCountTotal*3) for color in colorList)
    for level in levelList
      image   = imageList[level]
      for color in colorList
      extreme = extremeList[level].subarray(0, extremeCountList[level])
      border  = (kernelList[level].length>>1)+1
      sigma   = sigmaList[level]
      offset  = Feature.gaussian featureList, image, extreme, count0, count1
      for feature, color in featureList
        featureList[color] = feature.subarray(offsetList[color])
    for feature, color in featureList
      feature.subarray(0, featureList.length-feature.length)
