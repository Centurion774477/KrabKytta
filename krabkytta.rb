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

      # more than one expression on one line:
      # val foo: I32 = “bar”; print(foo);
      # The preferred approach is splitting that into two lines:
      # val foo: I32 = “bar”;
      # print(foo);
      if content.match?(/;.*;/)
        problems << "Line #{line_number} has two or more expressions on one line."
      end

      # avoid using the not operator (!) in while conditions:
      # while !hungry { ... }
      # There are two solutions to this:
      # 1. refactor into a repeat loop:
      # repeat { ... } until hungry
      # 2. change the variable name, preferably into the inverse.
      # For example, hungry -> full; tired -> energetic
      # while full { ... }
      if content.match?(/while !/)
        problems << <<-PROBLEM
        Line #{line_number} has a while loop with a negated condition.
        The preferred way to write this is to either use a repeat loop or to invert the variable name.

        Instead of:
        while !full { ... }

        You should write:
        repeat { ... } until full

        Or, you can invert the variable name:
        full turns into hungry

        while hungry { ... }
        PROBLEM
      end

      # this handles the opposite case — where they write repeat { ... } until !full
      if content.match?(/until !/)
        problems << <<-PROBLEM
        Line #{line_number} has a repeat loop with a negated condition.
        The preferred way to write this is to either use a while loop or to invert the variable name.

        Instead of:
        repeat { ... } until !hungry

        You should write:
        while hungry { ... }

        Or, you can invert the variable name:
        hungry turns into full

        repeat { ... } until full
        PROBLEM
      end
    end

    problems = check_when_blocks(file, problems)
    problems = check_var_usage(file, problems)

    if problems.empty?
      puts 'No problems were found in this file. Good work.'
    else
      problems.each { |problem| puts "#{problem}\n" }
    end
  end

  private

  # check for when blocks with only one condition
  def self.check_when_blocks(file, problems)
    lines             = []
    inside_when_block = false

    File.readlines(file).each_with_index do |line, index|
      if line.match?(/^\s*when\b/)
        inside_when_block = true
      elsif line.include?('}') && inside_when_block
        inside_when_block = false

        if lines.count == 1
          problems << <<~PROBLEM
            At around line #{index + 1} there is a when block with only one line.
            It's advised to convert this into a regular if statement.
          PROBLEM
        end

        lines.clear
      elsif inside_when_block
        lines << line
      end
    end

    problems
  end

  # This checks if you create variables using "var" and then don't reassign them.
  # In those cases, val should be used.
  def self.check_var_usage(file, problems)
    lines      = File.readlines(file)
    # name => line number where it was declared
    variables  = {}
    reassigned = []

    lines.each_with_index do |line, index|
      line_number = index + 1

      # var foo = ...
      declared = line.scan(/\bvar\s+(\w+)/).flatten
      declared.each { |name| variables[name] = line_number }

      # foo = ..., foo += ..., but not foo == / <= / >=,
      # and not the var declaration itself
      line.scan(/\b(\w+)\s*(?:\+|-|\*|\/)?=(?!=)/).flatten.each do |name|
        reassigned << name unless declared.include?(name)
      end
    end

    reassigned = reassigned.flatten.uniq

    variables.each do |name, line_number|
      next if reassigned.include? name

      problems << <<~PROBLEM
        On line #{line_number} you created #{name} using var but never reassigned it.
        var (mutable variables) should only be used when you need to reassign a variable.

        I suggest you use val to create this variable instead.
      PROBLEM
    end

    problems
  end

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

begin
  Krabkytta.check file
rescue StandardError
  # The most likely reason for KrabKytta to break is a malformed config file
  abort 'An error occured. Please ensure your krabkytta.yaml file is in order'
end

