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
require_relative 'models/status'
require_relative 'models/friendship'
require_relative 'models/chat'
enable :sessions


get '/' do
  redirect'/login' unless logged_in?
  # booklists section 
  @reading = Status.where(user_id: current_user.user_id, on_list: "reading").map{|a|a.book_id}
  @read = Status.where(user_id: current_user.user_id, on_list: "read").map{|a|a.book_id}
  @to_read = Status.where(user_id: current_user.user_id, on_list: "to_read").map{|a|a.book_id}

  # notification section
  books = Rating.where(user_id: current_user.user_id).map{|a|{ "book_id" =>a.book_id,"score"=>a.score}}
  @same_score_users =[]
  books.each do |book|
    Rating.where(book_id: book["book_id"], score: book["score"]).map do |person|
     user = User.find_by(user_id: person["user_id"])
      @same_score_users << user
      @same_score_users.delete current_user
    end
    @same_score_users.uniq!
  end 
  p 'my friendssssss'
  p @same_score_users

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
  redirect'/login' unless logged_in?
  @id =params[:id]

  # check if book is on user's lists
  if Status.exists?(user_id: current_user.user_id, book_id: params[:id])
    status = Status.find_by(user_id: current_user.user_id, book_id: params[:id])
    @on_list = status.on_list
  end 

  # check if have been rated by current user, if exists, diplaying the rating
  if Rating.exists?(user_id: current_user.user_id, book_id: params[:id])
    rating = Rating.find_by(user_id: current_user.user_id, book_id: params[:id])
    @current_score = rating.score
  else 
    @current_score = "rate now"
  end

  # check if book already saved in books table
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

    if @book["series_works"]!=nil &&@book["series_works"]["series_work"].class == Array
      book.series_title = @book["series_works"]["series_work"][0]["series"]["title"]
      book.series_number = @book["series_works"]["series_work"][0]["user_position"]
    elsif @book["series_works"]!=nil
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
  redirect'/login' unless logged_in?
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

put '/ratings/:id' do
  redirect'/login' unless logged_in?
  if Rating.exists?(user_id: current_user.user_id, book_id: params[:id])
    rating = Rating.find_by(user_id: current_user.user_id, book_id:params[:id])
    rating.score = params[:score]
    rating.save
  else
    rating = Rating.new
    rating.user_id = current_user.user_id
    rating.score = params[:score]
    rating.book_id = params[:id]
    rating.save
  end
  redirect "/book?id=#{params[:id]}"
end

put '/status/:id' do
  redirect'/login' unless logged_in?
  if Status.exists?(user_id: current_user.user_id, book_id:params[:id])
    status = Status.find_by(user_id: current_user.user_id, book_id:params[:id])
  else 
    status = Status.new
    status.book_id= params[:id]
    status.user_id = current_user.user_id
  end

  if params[:status] == "delete"
    status.destroy
  else 
    status.on_list = params[:status]
  end 
  status.save
  redirect "/book?id=#{params[:id]}"
end 

get '/user_details' do 
  erb :user_details
end 

get '/profile/:user_id' do 
  redirect'/login' unless logged_in?
  user_id = params[:user_id]
  @user = User.find_by(user_id: user_id)
  p !!@user.friendship
  p !!@user.dating

  @interets =[]
  if @user.friendship
    @interets.push "Making new friends"
  end
  if @user.dating
    @interets.push "Dating"
  end
  if @user.recommendation
    @interets.push "Finding good books"
  end

  if @user.debate
    @interets.push "Debating"
  end
  if @interets.length == 0
    @interets = ["#{@user.name} is too lazy to like anything!! Don't be like #{@user.name}."]
  end

  if Status.exists?(user_id: user_id)
     @friend_read_books = Status.where(user_id: user_id, on_list: "read").map{|a|Book.find_by(id: a.book_id)}
     p @friend_read_books
  end 

  if Friendship.exists?(id_from: current_user.user_id, id_to: user_id)
    @friendship= Friendship.find_by(id_from: current_user.user_id, id_to: user_id)
    @friendship_type = @friendship.friend_type
  end
  erb :profile
end 

get '/favorite/:id' do
  redirect'/login' unless logged_in?
  if Friendship.exists?(id_from: current_user.user_id, id_to: params[:id])
    friendship= Friendship.find_by(id_from: current_user.user_id, id_to: params[:id])
  else
    friendship = Friendship.new
    friendship.id_from = current_user.user_id
    friendship.id_to = params[:id]
  end
  friendship.friend_type ="favorite"
  friendship.save
  redirect "/profile/#{params[:id]}"
end

get '/block/:id' do
  redirect'/login' unless logged_in?
  if Friendship.exists?(id_from: current_user.user_id, id_to: params[:id])
    friendship= Friendship.find_by(id_from: current_user.user_id, id_to: params[:id])
  else
    friendship = Friendship.new
    friendship.id_from = current_user.user_id
    friendship.id_to = params[:id]
  end
  friendship.friend_type ="block"
  friendship.save
  redirect "/profile/#{params[:id]}"
end

get '/unblock/:id' do
  redirect'/login' unless logged_in?
  friendship= Friendship.find_by(id_from: current_user.user_id, id_to: params[:id])
  friendship.friend_type = ""
  friendship.save
  redirect "/profile/#{params[:id]}"
end
  