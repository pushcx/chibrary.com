# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_listlibrary_session',
  :secret      => 'f7af25caf416fd72620f5eff8f39fa75ea24efbf949c3eedf335323548c03723b39d6300e9da37cc473f11a8ab6631e5384b30a1cf8b2f5c183c722451c9a962'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
