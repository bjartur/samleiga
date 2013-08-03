#!/usr/bin/ruby
#coding: utf-8

require 'fileutils'
require 'cgi'
require 'bcrypt'
require 'securerandom'
require 'base64'

Lib = '/var/lib/samleiga/'

Browser = CGI.new()

def form(email)
	return %(<form method='POST' action='login'>
		<label>Netfang: <input name='email' value=')+email+%('></label>
		<label>Lykilorð: <input autofocus type='password'
		name='password'></label>
		<button type='submit'>Skrá</button>
	</form>)
end

def getCookie(browser, key)
	if browser.cookies.member? key
		return browser.cookies[key][0]
	else
		return false
	end
end
def auth?(browser)
	email = browser.cookies['email'][0]
	if !email
		return false
	else
		email.tr! "%", "="
		email = Base64.decode64 email
		email.gsub('\.\.') #TD
		fd = File.open(Lib+'/notandi/'+email+'/cookie')
		getCookie(browser, 'c') ==  fd.read
	end
end

status = 200
if auth?(Browser)
	msg = %(You're logged in!)
elsif not Browser.params.has_key?('email')
	msg = %(<form action='login'>
		<label>Sláðu inn netfang til að skrá þig inn.<br>
		<input autofocus type='email' name='email'></label>
		<button type='submit'>Skrá</button>
	</form>)
elsif Browser.params.has_key?('email')
	email = Browser.params['email'][0]
	email.gsub('\.\.') #TD
	notandi = %(/var/lib/samleiga/notandi/) + Browser.params['email'][0]
	if not File.exists?(notandi + '/password')
		if not Browser.params.has_key?('password')
			msg = %(<p>Þú hefur ekki sést áður. Veldu þér lykilorð.)+form(Browser.params['email'][0])
		else
			msg = %(Yay! Nýr notandi.)
			if not File.exists? notandi
				FileUtils.mkdir notandi
			end
			fd = File.new(notandi + '/password', 'w')
			fd.write BCrypt::Password.create Browser.params['password'][0]
		end
	else
		if not Browser.params.has_key?('password')
			msg = form(Browser.params['email'][0])
		else
			if BCrypt::Password.new(File.read(notandi + '/password')) == Browser.params['password'][0]
				msg = %(Access granted)
				cookie = SecureRandom.base64(24).gsub('/', '_')
				fd = File.new(Lib+'/notandi/' + email + '/cookie',  'w')
				fd.write(cookie)
				cookies = ['c=' + cookie, 'email=' + Base64.encode64(Browser.params['email'][0]).tr("=", "%")]
			else
				status = 403
				msg = %(Access denied)
			end
		end
	end
end
#elsif Browser.params.has_key?('email') and Browser.params.has_key?('password')
#	# Þetta er hættulegt. T.d. gæti netfangið verið ../../../etc/passwd
#	notandi = %(/var/lib/samleiga/notandi/) + Browser.params['email'][0]
#end

puts Browser.header('status' => status, 'cookie' => cookies, 'charset' => 'UTF-8')
puts %<<!DOCTYPE html><title>Innskráning</title>>
puts msg
