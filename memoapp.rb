# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'json'
require 'securerandom'
require 'erb'
require 'pg'

# DateBase class
class DateBase
  def initialize
    @conn = PG.connect(dbname: 'postgres')
    @conn.exec('
       CREATE TABLE IF NOT EXISTS memo
    (
    id serial primary key,
    title TEXT,
    memo text
    )')
  end

  def read
    @conn.exec('SELECT * FROM memo')
  end

  def select(id)
    @conn.exec_params('SELECT * FROM memo WHERE id=$1', [id])[0]
  end

  def insert(title, memo)
    @conn.exec_params('INSERT INTO memo (title, memo) VALUES ($1, $2)', [title, memo])
  end

  def delete(id)
    @conn.exec_params('DELETE FROM memo WHERE id=$1', [id])
  end

  def edit(title, memo, id)
    @conn.exec_params('UPDATE memo SET title=$1, memo=$2 WHERE id=$3', [title, memo, id])
  end
end

db = DateBase.new

get '/memos' do
  @memo_infos = db.read.map do |memo_info|
    memo_info['title'] = memo_info['title'].strip.empty? ? 'No title' : ERB::Util.html_escape(memo_info['title'])
    memo_info['memo'] = ERB::Util.html_escape(memo_info['memo'])
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
  @title = ERB::Util.html_escape(memo_info['title'])
  @memo = ERB::Util.html_escape(memo_info['memo'])
  erb :show
end

get '/memos/:id/edit' do
  @id = params[:id]
  memo_info = db.select(@id)
  @title = ERB::Util.html_escape(memo_info['title'])
  @memo = ERB::Util.html_escape(memo_info['memo'])
  erb :edit
end

post '/memos' do
  db.insert(params[:title], params[:memo])
  redirect '/memos'
end

delete '/memos/:id' do
  db.delete(params[:id])
  redirect '/memos'
end

patch '/memos/:id' do
  db.edit(params[:title], params[:memo], params[:id])
  redirect '/memos'
end
