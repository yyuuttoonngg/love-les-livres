# pry session with your data models loaded
require 'pry'
require_relative 'db_config'
require_relative 'models/book'
require_relative 'models/comment'
require_relative 'models/user'
require_relative 'models/rating'
require_relative 'models/status'
require_relative 'models/friendship'
require_relative 'models/chat'

binding.pry