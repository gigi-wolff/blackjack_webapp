require 'rubygems'
require 'sinatra'
require 'pry'

#set :sessions, true
use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'but_why'
BLACKJACK = 21
DEALER_STAYS_VALUE =17

helpers do
  def hand_total(hand)
    face_card = ['jack','queen','king','ace']
    total = 0
    hand.each do |card|
      if face_card.include?(card[0]) #is this a face card?
        if card[0]=='ace'
         total += 11
        else
         total += 10
        end
      else
        total += card[0].to_i
      end
    end
    # Set value of ace in hand to 1 if previous value of 11 causes bust
    total -=10 if (total>BLACKJACK && hand.flatten.include?('ace'))
    total 
  end

  def card_image(card) #['4',hearts']
    suit = card[1]
    value =card[0]
    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image' >"
  end
end

before do
  @show_hit_or_stay_buttons = true
end

get '/' do
 if session[:player_name]
   redirect '/game'
 else
    redirect '/new_player'
 end  
end

get '/new_player' do
  erb :new_player
end

post '/new_player' do
  if params[:player_name].empty?
    @error = "Name is required"
    halt erb(:new_player)
  end
  session[:player_name] = params[:player_name]  
  redirect '/game'
end

get '/game' do
  #set up init values and deal init cards
  suits = ['hearts', 'spades', 'clubs','diamonds']
  cards = ['2','3','4','5','6','7','8','9','10','jack','queen','king','ace']
  session[:deck] = cards.product(suits).shuffle!  
  session[:player_cards] = []
  session[:dealer_cards] = []
  
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop    
  
  redirect '/dealers_turn' if (hand_total(session[:player_cards])==BLACKJACK)
  erb :game
end

get '/dealers_turn' do 
  @dealers_playing = true
  @show_dealer_hit_button = false
  @show_hit_or_stay_buttons = false
  @play_again_button = true
  dealer_total = hand_total(session[:dealer_cards])
  player_total = hand_total(session[:player_cards])
  
  if player_total > BLACKJACK
    @error = "Sorry #{session[:player_name]}, you've busted with #{player_total}." 
  elsif (dealer_total < DEALER_STAYS_VALUE)
    @show_dealer_hit_button = true
    @play_again_button = false
  elsif (dealer_total > player_total && dealer_total <= BLACKJACK)
    @error = "Sorry #{session[:player_name]}, Dealer wins with #{dealer_total} ."
  elsif (dealer_total == player_total)
    @success = "#{session[:player_name]}, you and Dealer both have #{player_total}. Its a push."
  elsif (dealer_total > BLACKJACK || dealer_total < player_total)
    @success = "Congratulations #{session[:player_name]}! You win with #{player_total}!"
  else
    @play_again_button = false #no one won, game not over
  end   

  erb :game
end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect '/dealers_turn'
end

post '/game/player/hit' do 
  @dealers_playing = false
  session[:player_cards] << session[:deck].pop
  player_total = hand_total(session[:player_cards])
  redirect '/dealers_turn' if (player_total>=BLACKJACK)
  erb :game  
end

post '/game/player/stay' do
  @success = "#{session[:player_name]}, you've chosen to stay."
  redirect '/dealers_turn'
end

get '/game_over' do
  erb :game_over
end