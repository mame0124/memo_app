# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'json'
require 'securerandom'
require 'erb'

# DateBase class
class DateBase
  def read
    IO.readlines('memo.json').map { |memo_info| JSON.parse(memo_info, symbolize_names: true) }
  end

  def select(id)
    read.detect { |m| m[:id] == id }
  end

  def insert(params)
    new_memo_info = params
    new_memo_info['id'] = SecureRandom.uuid
    IO.write('memo.json', "#{new_memo_info.to_json}\n", mode: 'a')
  end

  def delete(id)
    new_memo_infos = read.reject { |memo_info| memo_info[:id] == id }
    IO.write('memo.json', new_memo_infos.map { |x| "#{x.to_json}\n" }.join)
  end

  def edit(new_memo_params)
    new_memo_infos = read.map do |memo_info|
      if memo_info[:id] == new_memo_params[:id]
        new_memo_params.delete('_method')
        new_memo_params
      else
        memo_info
      end
    end
    IO.write('memo.json', new_memo_infos.map { |x| "#{x.to_json}\n" }.join)
  end
end

db = DateBase.new

get '/memos' do
  @memo_infos = db.read.map do |memo_info|
    memo_info[:title] = memo_info[:title].strip.empty? ? 'No title' : ERB::Util.html_escape(memo_info[:title])
    memo_info[:memo] = ERB::Util.html_escape(memo_info[:memo])
    memo_info
  end
  erb :index
end

get '/memos/new' do
  erb :new
end

get '/memos/:id' do
  @id = params[:id]
  memo_info = db.select(@id)
  @title = ERB::Util.html_escape(memo_info[:title])
  @memo = ERB::Util.html_escape(memo_info[:memo])
  erb :show
end

get '/memos/:id/edit' do
  @id = params[:id]
  memo_info = db.select(@id)
  @title = ERB::Util.html_escape(memo_info[:title])
  @memo = ERB::Util.html_escape(memo_info[:memo])
  erb :edit
end

post '/memos' do
  db.insert(params)
  redirect '/memos'
end

delete '/memos/:id' do
  db.delete(params[:id])
  redirect '/memos'
end

patch '/memos/:id' do
  db.edit(params)
  redirect '/memos'
end
