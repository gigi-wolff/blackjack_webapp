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
    value = card[0]
    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image' >"
  end

  def who_won(player_total_value,dealer_total_value)
    if (player_total_value > BLACKJACK)
      'dealer'
    elsif (dealer_total_value > player_total_value && dealer_total_value <= BLACKJACK)
      'dealer'
    elsif (dealer_total_value == player_total_value)
      'tie'
    elsif (dealer_total_value > BLACKJACK || dealer_total_value < player_total_value) 
      'player'
    end
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

  @player_has_blackjack = true if hand_total(session[:player_cards])==BLACKJACK
  redirect '/dealers_turn' if @player_has_blackjack
  erb :game
end

get '/dealers_turn' do 
  @dealers_playing = true
  @show_dealer_hit_button = false
  @show_hit_or_stay_buttons = false
  @play_again_button = true
  dealer_total = hand_total(session[:dealer_cards])
  player_total = hand_total(session[:player_cards])
  
  if dealer_total < DEALER_STAYS_VALUE && player_total <= BLACKJACK   
    @show_dealer_hit_button = true
    @play_again_button = false
  else
    winner = who_won(player_total,dealer_total)
    @success = "Congratulations #{session[:player_name]}! You win with #{player_total}!" if winner=='player'
    @success = "#{session[:player_name]}, you and Dealer both have #{player_total}. Its a push."if winner=='tie'
    @error = "Sorry #{session[:player_name]}, you've lost with #{player_total}, dealer has #{dealer_total}." if winner=='dealer'
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
  @player_has_blackjack = true if player_total==BLACKJACK
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