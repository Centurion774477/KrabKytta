# frozen_string_literal: true

# This Ruby file was written by Reece Turner (reeceturner1358@gmail.com)
# For usage in KrabbaScript (https://github.com/khytryy/krabbascript)

require 'yaml'

# the main engine for Krabkytta
class Krabkytta
  def self.check file
    config_path = 'krabkytta.yaml'

    unless File.exist? config_path
      abort 'No config file exists. Please write a krabkytta.yaml file'
    end

    unless file && File.exist?(file)
      abort 'The file you passed does not exist'
    end

    if File.zero? file
      abort 'The file you passed is empty. Please pass a file with content'
    end

    config = read_yaml

    ['lines cant be over', 'variable name scheme is', 'deprecated words or symbols'].each do |key|
      abort "#{key} is missing in krabkytta.yaml" unless config[key]
    end

    character_limit   = config['lines cant be over']
    name_scheme_word  = config['variable name scheme is']
    deprecated_values = config['deprecated words or symbols']

    character_limit = character_limit.gsub("characters", "").to_i
    naming_scheme = regexify_naming_scheme name_scheme_word

    problems = []
    File.readlines(file).each_with_index do |line, index|
      line_number = index + 1
      content     = line.chomp

      if content.length > character_limit
        problems << "Line #{line_number} has #{content.length} characters which is over the limit of #{character_limit} characters"
      end

      if (deprecated = deprecated_values.find { |word| content.include? word })
        problems << "Line #{line_number} contains #{deprecated}; usage of such a value is deprecated."
      end

      # naming scheme
      # TODO make this more detailed—
      # Right now it will throw a lot of false negatives
      next if content.strip.empty? # don't flag blank lines

      unless content.match? naming_scheme
        problems << "Line #{line_number} does not match the naming scheme #{name_scheme_word}"
      end
    end

    if problems.empty?
      puts 'No problems were found in this file. Good work.'
    else
      problems.each { |problem| puts problem }
    end
  end

  private

  def self.read_yaml
    YAML.load_file 'krabkytta.yaml'
  end

  # users pass values like camelCase or snake_case
  # We need to convert those to regex patterns so we can match against them.
  def self.regexify_naming_scheme(naming_scheme)
    case naming_scheme
    when 'camelCase' then /\b[A-Z]?[a-z]+(?:[A-Z][a-z0-9]*)*\b/
    when 'snake_case' then /\b[a-z0-9]+(?:_[a-z0-9]+)*\b/
    else /.*/m # capture anything; any naming scheme will be valid
    end
  end
end

file = ARGV[0]

abort 'Please pass a file to check' unless file

Krabkytta.check file

