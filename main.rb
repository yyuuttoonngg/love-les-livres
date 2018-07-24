require 'sinatra'
require 'sinatra/reloader'
require 'pg'
require 'httparty'
# require 'active_support'
require_relative 'db_config'
require_relative 'models/book'
require_relative 'models/user'
require_relative 'models/rating'
require_relative 'models/comment'
enable :sessions

get '/' do
  erb :index
end

get '/search' do
  @input = params[:name]
  @input = URI.encode(@input)
  if @input ==''
    redirect '/'
  else
    url = "https://www.goodreads.com/search/index.xml?key=BVBuna3XmFczBJfVWObKeg&q=#{@input}"
    results = HTTParty.get(url)
    @book_results = results.parsed_response["GoodreadsResponse"]["search"] 
    if @book_results["results"] == nil
      redirect '/error'
    elsif @book_results["total_results"] == "1"
      redirect "/book?id=#{@book_results["results"]["work"]["best_book"]["id"]}"
    else
      @books = @book_results["results"]["work"]
    end
  end
  erb :search
end

get '/error' do
  erb :error
end 

get '/book' do
  @id =params[:id]
  if Book.exists?(id=@id) 
    @book = Book.find(@id)
  else
    url = "https://www.goodreads.com/book/show/#{@id}?key=BVBuna3XmFczBJfVWObKeg"
    results = HTTParty.get(url)
    @book = results.parsed_response["GoodreadsResponse"]["book"]
    book = Book.new
    book.id = @id
    book.title = @book["title"]
    if @book["authors"].length == 1 && @book["authors"]["author"].class == Hash
      book.author = @book["authors"]["author"]["name"]
    else
      book.author = @book["authors"]["author"][0]["name"]
    end

    if @book["series_works"]["series_work"].class == Array
      book.series_title = @book["series_works"]["series_work"][0]["series"]["title"]
      book.series_number = @book["series_works"]["series_work"][0]["user_position"]
    else
      book.series_title = @book["series_works"]["series_work"]["series"]["title"]
      book.series_number = @book["series_works"]["series_work"]["user_position"]
    end 
    book.publication_year = @book["publication_year"]
    book.image_url = @book["image_url"]
    book.small_image_url = @book["small_image_url"]
    book.description = @book["description"]
    book.goodreadrating = @book["average_rating"]
    book.ratings_count = @book["ratings_count"]
    book.save
    @book = Book.find(@id)
  end
  erb :book
end

get '/account' do
  erb :account
end

get '/login' do
  erb :login
end 

get '/signup' do
  erb :signup
end 

post '/session' do
  user = User.find_by(email: params[:email])
  if user && user.authenticate(params[:password])
    session[:user_id] = user.id
    redirect '/'
  else 
    erb :login
  end
end 

delete '/session' do
  session[:user_id] = nil
  redirect '/login'
end

def current_user
  User.find_by(user_id: session[:user_id])
end 

def logged_in?
  !!current_user
end 

post '/rating' do
  redirect'/login' unless logged_in?
end

post '/signup' do
  p 'signup'
  if User.exists?(email: params[:email])
    p 'email taken'
    redirect '/login'
  else
    p 'new user'
    user = User.new
    user.email = params[:email]
    user.name = params[:name]
    user.password = params[:password]
    user.save
    redirect '/'
  end

end 