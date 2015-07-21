Image = require './image'
Surface = require './surface'
Measure = require './measure'
Suppress = require './suppress'

fround = Math.fround
sqrt = Math.sqrt
exp = Math.exp
abs = Math.abs
ceil = Math.ceil
pow = Math.pow
pi = Math.PI
tau = pi*2

erf = (x)->
  t = 1/(1+0.3275911*abs(x))
  y = 1-((((1.061405429*t-1.453152027)*t+1.421413741)*t-0.284496736)*t+0.254829592)*t*exp(-x*x)
  if x > 0 then y else -y

gaussian = (sigma)->
  length = ceil(sigma*6)|1
  radius = length/2
  kernel = new Float32Array(length)
  constant = 1/sqrt(tau)/sigma
  for i in [0..length-1]
    x0 = (i-radius)/sigma/sqrt(2)
    x1 = (i+1-radius)/sigma/sqrt(2)
    y = (erf(x1)-erf(x0))/2
    kernel[i] = y
  kernel

element = (surface, width, height)->
  canvas = document.createElement("canvas")
  context = canvas.getContext("2d")
  imageData = Image.compact surface, context, width, height
  canvas.width = imageData.width
  canvas.height = imageData.height
  context.putImageData imageData, 0, 0
  canvas

(()->
  Image.load 'https://farm1.staticflickr.com/194/505494059_426290217e.jpg', (imageData)->

    width = imageData.width
    height = imageData.height

    i_count = height*2
    j_count = width*2

    levels = 4
    sigmaList = (pow(2, 1+(level-1)/levels) for level in [0..levels+1])
    kernelList = (gaussian(sigmaList[level]) for level in [0..levels+1])

    surface0 = Image.extract imageData
    surface1 = new Float32Array(surface0.length)
    surfaceList = (new Float32Array(surface0.length) for level in [0..levels+1])
    measureList = (new Float32Array(surface0.length) for level in [0..levels+1])
    extremeList = (new Int32Array(surface0.length>>4) for level in [0..levels+1])
    countList = (0 for level in [0..levels+1])

    for level in [0..levels+1]
      kernel = kernelList[level]
      radius = kernel.length>>1
      console.log level, kernel.length

      surface = surfaceList[level].subarray(radius*(j_count+1))
      Surface.convolute surface1, surface0, kernel, 
        i_count-radius*2, j_count, j_count, 1, kernel.length, j_count
      Surface.convolute surface, surface1, kernel, 
        i_count-radius*2, j_count, j_count-radius*2, 1, kernel.length, 1

    colorList = [
      'rgba(0,0,0, 0.25)',
      'rgba(255,0,0, 0.25)',
      'rgba(0,255,0, 0.25)',
      'rgba(0,0,255, 0.25)',
      'rgba(255,255,255, 0.25)',
      'rgba(0,255,255, 0.25)',
      'rgba(255,0,255, 0.25)',
      'rgba(255,255,0, 0.25)',
    ]

    for name, measure of Measure
      console.log name

      for level in [0..levels+1]
        measure measureList[level], surfaceList[level], sigmaList[level], 
          i_count, j_count, j_count, 1

      for level in [1..levels]
        countList[level] = Suppress.neighbor_18 extremeList[level],
          measureList[level-1], measureList[level], measureList[level+1], 
          i_count, j_count, j_count, 1
        console.log level, countList[level]

      canvas = document.createElement("canvas")
      canvas.width = width
      canvas.height = height

      context = canvas.getContext("2d")
      context.globalCompositeOperation = "multiply"

      for level in [0..levels]
        continue if countList[level] == 0
        surface = surfaceList[level]
        extreme = extremeList[level]
        border = (kernelList[level].length>>1)+1
        sigma = sigmaList[level]

        s1_2 = fround(sigma/2)
        s2_1 = fround(sigma*sigma)
        s2_4 = fround(sigma*sigma/4)

        for index in [0..countList[level]-1]
          k = extreme[index]

          color = 0; scale = -1
          if k < 0 then k = -k; color |= 4
          i0 = (k/j_count)|0; i1 = i_count
          j0 = (k%j_count)|0; j1 = j_count
          while i1 >= i0 and j1 >= j0
            i1 >>= 1; j1 >>= 1; scale += 1
          if i0 >= i1 then i0 -= i1; color |= 2
          if j0 >= j1 then j0 -= j1; color |= 1

          if i0 < border or i0 >= i1-border or 
             j0 < border or j0 >= j1-border
            continue

          k0 = k-i_count; k1 = k; k2 = k+i_count
          e00 = surface[k0-j_count]; e01 = surface[k0]; e02 = surface[k0+j_count]
          e10 = surface[k1-j_count]; e11 = surface[k1]; e12 = surface[k1+j_count]
          e20 = surface[k2-j_count]; e21 = surface[k2]; e22 = surface[k2+j_count]

          _   = e11
          _j  = fround(s1_2*(e21-e01))
          _i  = fround(s1_2*(e12-e10))
          _jj = fround(s2_1*(e01+e21-e11-e11))
          _ii = fround(s2_1*(e10+e12-e11-e11))
          _ij = fround(s2_4*(e00+e22-e02-e20))

          context.beginPath()
          context.arc j0<<scale, i0<<scale, 2<<scale, 0, tau
          context.fillStyle = colorList[color]
          context.fill()

      page = document.getElementsByClassName("page")[0]
      slide = document.createElement("div")
      slide.className = 'slide'
      container = document.createElement("div")
      container.className = 'container'
      page.appendChild slide
      slide.appendChild container
      container.appendChild canvas
)()
