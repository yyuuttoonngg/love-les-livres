require 'active_record'

options ={
    adapter: 'postgresql',
    database: 'booklist'
}

ActiveRecord::Base.establish_connection( ENV['DATABASE_URL'] || options)