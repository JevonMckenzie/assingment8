require 'sinatra/base'
require 'sinatra'
require 'nbasalaryscrape'
require 'json'

# nbasalaryscrape service
class TeamPayApp < Sinatra::Base
  helpers do
    def get_team(teamname)
      var = SalaryScraper::BasketballReference.new
      var.to_array_of_hashes(teamname.upcase)
    end

    def get_team_players(teamname)
      team = get_team(teamname)
      team_players = []
      team.each do |player_salary_scrape|
        team_players << player_salary_scrape['Player']
      end
      team_players
    end

    def player_salary_data(teamname, player_name)
      salary_scrape = get_team(teamname[0])
      player_scrape = []
      player_name.each do |each_player|
        salary_scrape.each do |data_row|
          player_scrape <<  data_row  if data_row['Player'] == each_player
        end
      end
      player_scrape
    end

    def one_total(data_row, each_player)
      player_scrape, fullpay = 0, []
      player_scrape +=  parse_money(data_row['2014-15'])
      player_scrape +=  parse_money(data_row['2015-16'])
      player_scrape +=  parse_money(data_row['2016-17'])
      player_scrape +=  parse_money(data_row['2017-18'])
      player_scrape +=  parse_money(data_row['2018-19'])
      player_scrape +=  parse_money(data_row['2019-20'])
      fullpay << { 'player' => each_player,
                   'fullpay' => back_to_money(player_scrape) }
      fullpay
    end

    def player_total_salary(teamname, player_name)
      players = []
      salary_scrape = get_team(teamname[0])
      player_name.each do |each_player|
        salary_scrape.each do |data_row|
          if data_row['Player'] == each_player
            players << one_total(data_row, each_player)
          end
        end
      end
      players
    end

    def parse_money(money)
      data = money.gsub(/[$,]/, '$' => '', ',' => '')
      data.to_i
    end

    def back_to_money(data)
      money = "$#{data.to_s.reverse.gsub(/...(?=.)/, '\&,').reverse}"
      money
    end
  end

  get '/api/v1/:teamname.json' do
    content_type :json
    get_team(params[:teamname]).to_json
  end
  get '/api/v1/form' do
    erb :form
  end
  post '/form' do
    content_type :json
    get_team(params[:message]).to_json
  end
  not_found do
    status 404
    'not found'
  end

  post '/api/v1/check' do
    content_type :json
    req = JSON.parse(request.body.read)
    teamname = req['teamname']
    player_name = req['player_name']
    player_salary_data(teamname, player_name).to_json
  end
  post '/api/v1/check2' do
    content_type :json
    req = JSON.parse(request.body.read)
    teamname = req['teamname']
    player_name = req['player_name']
    player_total_salary(teamname, player_name).to_json
  end

  get '/api/v1/players/:teamname.json' do
    content_type :json
    get_team_players(params[:teamname]).to_json
  end

  get '/' do
    erb :index
  end
end
