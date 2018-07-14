# frozen_string_literal: true

require "#{ENV['HOME']}/.dots/ruby/console_colors"

class ConsolePrompt
  def initialize(prefix, object=nil, level=0)
    @prefix = prefix
    @object = object
    @level = level
  end

  def normal
    prefix + info + context + level + suffix(:cyan)
  end

  def continue
    prefix + info + context + level + suffix(:yellow)
  end

  def return
    "#{colors[:light_yellow]}=>#{colors[:reset]} %s\n"
  end

private

  def prefix
    prefix = [
      separator,
      separator(:blue),
      separator,
      ' '
    ]

    unless @prefix.nil?
      prefix = [
        colors[:bold],
        colors[:dark_gray],
        @prefix,
        colors[:reset],
        ' '
      ] + prefix
    end

    prefix.join
  end

  def info
    info = [
      colors[:reset],
      colors[:bold],
      colors[:blue]
    ]
    info << (
      if ENV.key?('PROMPT_NAME')
        ENV['PROMPT_NAME']
      elsif defined?(Rails) && Rails.respond_to?(:application)
        Rails.application.class.name.gsub('::Application', '')
      else
        RUBY_VERSION.to_s
      end
    )
    info << colors[:reset]
    info.join
  end

  def context
    return '' unless defined?(Pry)
    context = Pry.view_clip(@object)
    return '' if context == 'main'
    context = context.to_s.gsub('#<', '').delete('>')
    context = '*::' + context.gsub(/.*::/, '') if context.include?('::')
    [
      ' ',
      colors[:light_red],
      context,
      colors[:reset]
    ].join
  end

  def level
    return '' if @level.zero?
    [
      ' ',
      colors[:reset],
      colors[:bold],
      colors[:magenta],
      @level.to_s,
      colors[:reset]
    ].join
  end

  def suffix(color)
    ' ' + separator(color) + ' ' + colors[:reset]
  end

  def separator(color=:magenta)
    "#{colors[:bold]}#{colors[color]}❯#{colors[:reset]}"
  end

  def colors
    CONSOLE_COLORS
  end
end
