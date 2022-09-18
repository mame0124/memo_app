# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'json'
require 'securerandom'

# DateBase class
class DateBase
  require 'erb'
  include ERB::Util

  def read
    IO.readlines('memo.json').map { |memo_info| JSON.parse(memo_info, symbolize_names: true) }
  end

  def select(id)
    read.detect { |m| m[:id] == id }
  end

  def insert(params)
    new_memo_info = memo_info_escape(params)
    new_memo_info['id'] = SecureRandom.uuid
    IO.write('memo.json', "#{new_memo_info.to_json}\n", mode: 'a')
  end

  def memo_info_escape(memo_info)
    memo_info['title'] = if memo_info['title'].strip.empty?
                           'No title'
                         else
                           html_escape(memo_info['title'])
                         end
    memo_info['memo'] = html_escape(memo_info['memo'])
    memo_info
  end

  def delete(id)
    new_memo_infos = read.reject { |memo_info| memo_info[:id] == id }
    IO.write('memo.json', new_memo_infos.map { |x| "#{x.to_json}\n" }.join)
  end

  def edit(new_memo_params)
    new_memo_infos = read.map do |memo_info|
      if memo_info[:id] == new_memo_params[:id]
        new_memo_params.delete('_method')
        memo_info_escape(new_memo_params)
      else
        memo_info
      end
    end
    IO.write('memo.json', new_memo_infos.map { |x| "#{x.to_json}\n" }.join)
  end
end

db = DateBase.new

get '/memos' do
  @memo_infos = db.read
  erb :index
end

get '/memos/new' do
  erb :new
end

get '/memos/:id' do
  @id = params[:id]
  memo_info = db.select(@id)
  @title = memo_info[:title]
  @memo = memo_info[:memo]
  erb :show
end

get '/memos/:id/edit' do
  @id = params[:id]
  memo_info = db.select(@id)
  @title = memo_info[:title]
  @memo = memo_info[:memo]
  erb :edit
end

post '/memos' do
  db.insert(params)
  redirect 'http://localhost:4567/memos'
end

delete '/memos/:id' do
  db.delete(params[:id])
  redirect 'http://localhost:4567/memos'
end

patch '/memos/:id' do
  db.edit(params)
  redirect 'http://localhost:4567/memos'
end
