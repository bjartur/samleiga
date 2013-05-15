#!/usr/bin/ruby
#coding: utf-8

require 'fileutils'
require 'cgi'
require 'bcrypt'
require 'securerandom'

cgi = CGI.new

def form(email)
	return "<form method='POST' action='login'>
		<label>Netfang: <input name='email' value='" +email+ "'></label>
		<label>Lykilorð:
		<input autofocus type='password' name='password'></label>
		<button type='submit'>Skrá</button>
	</form>"
end

status = 200
if not cgi.params.has_key?('email')
	msg = '<form action="login">
		<label>Sláðu inn netfang til að skrá þig inn.<br>
		<input autofocus type="email" name="email"></label>
		<button type="submit">Skrá</button>
	</form>'
elsif cgi.params.has_key?('email')
	notandi = "/var/lib/samleiga/notandi/" + cgi.params['email'][0]
	if not File.exists?(notandi + '/password')
		if not cgi.params.has_key?('password')
			msg = "<p>Þú hefur ekki sést áður. Veldu þér lykilorð."+form(cgi.params['email'][0])
		else
			msg = "Yay! Nýr notandi."
			if not File.exists? notandi
				FileUtils.mkdir notandi
			end
			fd = File.new(notandi + '/password', 'w')
			fd.write BCrypt::Password.create cgi.params['password'][0]
		end
	else
		if not cgi.params.has_key?('password')
			msg = form(cgi.params['email'][0])
		else
			if BCrypt::Password.new(File.read(notandi + '/password')) = cgi.params['password'][0]
				msg = "Access granted"
				cookie = SecureRandom.base64(24)
				cookie.gsub('/', '_')
				fd = File.new('/var/lib/samleiga/cookie/' + cookie, 'w')
				fd.write(cgi.params['email'])
				cookie = 's=' + cookie
			else
				status = 403
				msg = "Access denied"
			end
		end
	end
elsif cgi.params.has_key?('email') and cgi.params.has_key?('password')
	# Þetta er brothætt. T.d. gæti netfangið verið ../../../etc/passwd
	notandi = "/var/lib/samleiga/notandi/" + cgi.params['email'][0]
end

puts cgi.header('status' => status, 'cookie' => cookie, 'charset' => 'UTF-8')
puts "<!DOCTYPE html><title>Innskráning</title>"
puts msg
