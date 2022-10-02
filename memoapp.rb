# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'json'
require 'securerandom'
require 'erb'
require 'pg'

# DataBase class
class DataBase
  def initialize
    sql = <<-SQL
      CREATE TABLE IF NOT EXISTS memo
      (
      id SERIAL PRIMARY KEY,
      title TEXT,
      memo TEXT
      )
      SQL
    @conn = PG.connect(dbname: 'postgres')
    @conn.exec(sql)
  end

  def read
    @conn.exec('SELECT * FROM memo ORDER BY id')
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

db = DataBase.new

get '/memos' do
  @memos = db.read.map do |memo|
    memo['title'] = memo['title'].strip.empty? ? 'No title' : ERB::Util.html_escape(memo['title'])
    memo['memo'] = ERB::Util.html_escape(memo['memo'])
    memo
  end
  erb :index
end

get '/memos/new' do
  erb :new
end

get '/memos/:id' do
  @id = params[:id]
  memo = db.select(@id)
  @title = ERB::Util.html_escape(memo['title'])
  @memo = ERB::Util.html_escape(memo['memo'])
  erb :show
end

get '/memos/:id/edit' do
  @id = params[:id]
  memo = db.select(@id)
  @title = ERB::Util.html_escape(memo['title'])
  @memo = ERB::Util.html_escape(memo['memo'])
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
