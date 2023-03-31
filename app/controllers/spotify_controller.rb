class SpotifyController < ApplicationController
  before_action :authenticate_spotify_api

  def index
    @playlists = current_user.playlists
  end

  def create_playlist
    # Cria uma playlist colaborativa no Spotify
    uri = URI('https://api.spotify.com/v1/users/spotify/playlists')
    req = Net::HTTP::Post.new(uri)
    req.content_type = 'application/json'
    req['Authorization'] = "Bearer #{@spotify_token}"
    req.body = {
      name: 'Minha Playlist Colaborativa',
      public: false,
      collaborative: true
    }.to_json

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(req)
    end

    if res.is_a?(Net::HTTPSuccess)
      playlist_data = JSON.parse(res.body)
      playlist = current_user.playlists.create(
        name: playlist_data['name'],
        spotify_id: playlist_data['id']
      )
      redirect_to playlist_path(playlist)
    else
      flash[:error] = "Erro ao criar playlist: #{res.body}"
      redirect_to root_path
    end
  end

  def add_track_to_playlist
    playlist = current_user.playlists.find(params[:playlist_id])

    # Adiciona uma música à playlist colaborativa no Spotify
    uri = URI("https://api.spotify.com/v1/playlists/#{playlist.spotify_id}/tracks")
    req = Net::HTTP::Post.new(uri)
    req.content_type = 'application/json'
    req['Authorization'] = "Bearer #{@spotify_token}"
    req.body = { uris: [params[:track_uri]] }.to_json

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(req)
    end

    if res.is_a?(Net::HTTPSuccess)
      playlist.tracks.create(spotify_uri: params[:track_uri])
      redirect_to playlist_path(playlist)
    else
      flash[:error] = "Erro ao adicionar música à playlist: #{res.body}"
      redirect_to playlist_path(playlist)
    end
  end

  def remove_track_from_playlist
    playlist = current_user.playlists.find(params[:playlist_id])

    # Remove uma música da playlist colaborativa no Spotify
    uri = URI("https://api.spotify.com/v1/playlists/#{playlist.spotify_id}/tracks")
    req = Net::HTTP::Delete.new(uri)
    req.content_type = 'application/json'
    req['Authorization'] = "Bearer #{@spotify_token}"
    req.body = { tracks: [{ uri: params[:track_uri] }] }.to_json

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(req)
    end

    if res.is_a?(Net::HTTPSuccess)
      playlist.tracks.find_by(spotify_uri: params[:track_uri]).destroy
      redirect_to playlist_path(playlist)
    else
      flash[:error] = "Erro ao remover música da playlist: #{res.body}"
      redirect_to playlist_path(playlist)
    end
  end
  def get_playlist_history
    playlist = current_user.playlists.find(params[:playlist_id])

    # Obtém o histórico de todas as músicas tocadas na playlist colaborativa no Spotify
    uri = URI("https://api.spotify.com/v1/playlists/#{playlist.spotify_id}/tracks")
    req = Net::HTTP::Get.new(uri)
    req['Authorization'] = "Bearer #{@spotify_token}"

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(req)
    end

    if res.is_a?(Net::HTTPSuccess)
      playlist_history = JSON.parse(res.body)['items'].map { |item| item['track']['uri'] }
      playlist.update(history: playlist_history)
      redirect_to playlist_path(playlist)
    else
      flash[:error] = "Erro ao obter histórico da playlist: #{res.body}"
      redirect_to playlist_path(playlist)
    end
  end

  private

  def authenticate_spotify_api
    client_id = 'db1a61be0ff94c9fbef3aadb1894e5b2'
    client_secret = '9e755e3fc92c4941815072b1a090314c'

    # Obtém um token de acesso para a API do Spotify
    uri = URI('https://accounts.spotify.com/api/token')
    req = Net::HTTP::Post.new(uri)
    req['Authorization'] = "Basic #{Base64.strict_encode64("#{client_id}:#{client_secret}")}"
    req.set_form_data(grant_type: 'client_credentials')

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(req)
    end

    if res.is_a?(Net::HTTPSuccess)
      @spotify_token = JSON.parse(res.body)['access_token']
    else
      flash[:error] = "Erro ao autenticar com a API do Spotify: #{res.body}"
      redirect_to root_path
    end
  end






end
