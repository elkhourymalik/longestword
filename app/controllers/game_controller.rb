require 'open-uri'
require 'json'
class GameController < ApplicationController

  def difficulty
  end

  def game
    @grid_size = params[:grid_size]
    @grid = generate_grid(@grid_size.to_i)
    @start_time = Time.now
  end

  def score
    @end_time = Time.now
    @start_time = Time.parse(params[:start_time])
    @grid = params[:grid].split
    @attempt = params[:attempt]
    @result = run_game(@attempt, @grid, @start_time, @end_time)
    @time_taken = @result[:time]
    @translation = @result[:translation]
    @score = @result[:score]
    @message = @result[:message]
  end

  private
  def generate_grid(grid_size)
    Array.new(grid_size) { ('A'..'Z').to_a[rand(26)] }
  end

  def included?(guess, grid)
    the_grid = grid.clone
    guess.chars.each do |letter|
      the_grid.delete_at(the_grid.index(letter)) if the_grid.include?(letter)
    end
    grid.size == guess.size + the_grid.size
  end

  def compute_score(attempt, time_taken)
    (time_taken > 60.0) ? 0 : attempt.size * (1.0 - time_taken / 60.0)
  end

  def run_game(attempt, grid, start_time, end_time)
    result = { time: end_time.to_i - start_time.to_i }

    result[:translation] = get_translation(attempt)
    result[:score], result[:message] = score_and_message(
      attempt, result[:translation], grid, result[:time])
    result
  end

  def score_and_message(attempt, translation, grid, time)
    if translation
      if included?(attempt.upcase, grid)
        score = compute_score(attempt, time)
        [score, "well done"]
      else
        [0, "not in the grid"]
      end
    else
      [0, "not an english word"]
    end
  end

  def get_translation(word)
    response = open("http://api.wordreference.com/0.8/80143/json/enfr/#{word.downcase}")
    json = JSON.parse(response.read.to_s)
    json['term0']['PrincipalTranslations']['0']['FirstTranslation']['term'] unless json["Error"] || json["Response"]
  end
end
