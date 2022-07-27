require_relative 'pythagoras'
require_relative 'display'
require 'pry'

program = Pythagoras::Program.read_state
program = Pythagoras::Program.new unless program
#program.run