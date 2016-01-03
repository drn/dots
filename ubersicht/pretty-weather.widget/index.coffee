apiKey   = '5c363c151c2e6b9771a727ff556ab69b' # developer.forecast.io
location = '37.771971,-122.425316'            # 100 Laguna St., SF
exclude  = "minutely,hourly,alerts,flags"

# primaryColor   = "#151535" # dark blue
primaryColor   = "#AAA" # light gray

command: "curl -sS 'https://api.forecast.io/forecast/#{apiKey}/#{location}?units=auto&exclude=#{exclude}' 2>/dev/null"

refreshFrequency: 60000

svgNs: 'xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"'

render: (o) -> """
  <svg #{@svgNs} width="200px" height="200px" >
    <defs xmlns="http://www.w3.org/2000/svg">
      <mask id="icon_mask">
        <rect width="100px" height="100px" x="50" y="50" fill="#fff"
              transform="rotate(45 100 100)"/>
        <text class="icon"
              x="50%" y='45%'></text>

        <text class="temp"
              x="50%" y='65%' dx='3px'></text>
      </mask>
      <mask id="date_mask">
        <rect x='0' y="0" width="200px" height="200px" fill='#fff'/>
        <text class="date mask"
            textLength='90px'
            transform="rotate(-45 100 100)"
            x="50%" y='42px'></text>
      </mask>
    </defs>

    <g mask="url(#date_mask)">
      <rect class='outline' width="100px" height="100px" x="50" y="50"/>
      <rect class='outline' width="100px" height="100px" x="50" y="50"
            transform="rotate(21 100 100)"/>
      <rect class='outline' width="100px" height="100px" x="50" y="50"
            transform="rotate(66 100 100)"/>
    </g>

    <rect class='icon-bg' width="200px" height="200px" x="0" y="0"

          mask="url(#icon_mask)"/>

    <text class="date"
          textLength='90px'
          transform="rotate(-45 100 100)"
          x="50%" y='42px'></text>
  </svg>
  <div class='summary'></div>
"""

update: (output, domEl) ->
  data  = JSON.parse(output)
  current = data.currently
  date  = @getDate current.time

  $(domEl).find('.temp')[0].textContent = Math.round(current.temperature)+'°'
  $(domEl).find('.summary').text current.summary
  $(domEl).find('.icon')[0]?.textContent = @getIcon(current)
  $(domEl).find('.date').prop('textContent',@dayMapping[date.getDay()])

style: """
  top: 2%
  left: 50%
  margin: 0 0 0 -100px
  font-family: Helvetica Neue
  color: #{primaryColor}

  @font-face
    font-family Weather
    src url(pretty-weather.widget/icons.svg) format('svg')

  .icon
    font-family: Weather
    font-size: 40px
    text-anchor: middle
    alignment-baseline: middle

  .temp
    font-size: 20px
    text-anchor: middle
    alignment-baseline: baseline

  .outline
    fill: none
    stroke: #{primaryColor}
    stroke-width: 0.5

  .icon-bg
    fill: rgba(#{primaryColor}, 0.95)

  .summary
    text-align: center
    border-top: 1px solid #{primaryColor}
    padding: 12px 0 0 0
    margin-top: -20px
    font-size: 14px
    max-width: 200px
    line-height: 1.4
    text-shadow: 1px 1px 15px #000

  .date
    fill: #{primaryColor}
    stroke: #{primaryColor}
    stroke-width: 1px
    font-size: 12px
    text-anchor: middle

  .date.mask
    stroke: #999
    stroke-width: 5px
"""

dayMapping:
  0: 'Sunday'
  1: 'Monday'
  2: 'Tuesday'
  3: 'Wednesday'
  4: 'Thursday'
  5: 'Friday'
  6: 'Saturday'

iconMapping:
  "rain"                :"\uf019"
  "snow"                :"\uf01b"
  "fog"                 :"\uf014"
  "cloudy"              :"\uf013"
  "wind"                :"\uf021"
  "clear-day"           :"\uf00d"
  "mostly-clear-day"    :"\uf00c"
  "partly-cloudy-day"   :"\uf002"
  "clear-night"         :"\uf02e"
  "partly-cloudy-night" :"\uf031"
  "unknown"             :"\uf03e"

getIcon: (data) ->
  return  @iconMapping['unknown'] unless data

  if data.icon.indexOf('cloudy') > -1
    if data.cloudCover < 0.25
      @iconMapping["clear-day"]
    else if data.cloudCover < 0.5
      @iconMapping["mostly-clear-day"]
    else if data.cloudCover < 0.75
      @iconMapping["partly-cloudy-day"]
    else
      @iconMapping["cloudy"]
  else
    @iconMapping[data.icon]

getDate: (utcTime) ->
  date  = new Date(0)
  date.setUTCSeconds(utcTime)
  date
