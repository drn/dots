file = '/Users/darrencheng/Dropbox/To Darren.txt'

# command: "cat '#{file}' | sed ':a;N;$!ba;s/\n/ /g'"
command: "contents=$(cat '#{file}'); echo ${contents//$'\n'/'<br>'}"

refreshFrequency: 60000

render: (o) -> """
  <div class='content'>#{o}</div>
"""

style: """
  bottom: 13%
  left: 50%
  margin-left: -300px
  color: #fff
  text-shadow: 5px 5px 5px #000;
  font-family: Tangerine, Snell Roundhand, Helvetica Neue
  font-weight: bold
  font-size: 24px
  text-align: center
  overflow: hidden

  .note
    width: 600px
    height: 140px
"""

render: -> """
  <div class='note'></div>
"""

update: (output, domEl) ->
  $(domEl).find('.note').html(output)
