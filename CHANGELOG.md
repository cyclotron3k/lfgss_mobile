# Changelog

## v1.0.34

- Better layout in Android 15
- Fix parsing of some profile links

## v1.0.33

- Better cache management (don't cache failed requests)
- Do logout properly
- Major updates
- Fix rendering of mentions in DMs, in Updates page.

## v1.0.32

- Better light-mode colours

## v1.0.31

- Clear obsolete notifications
- Hand off unrecognised attachments to the OS
- Add map link to events

## v1.0.30

- Fix swipe-to-reply causing widget rebuilds

## v1.0.29

- Fix Flickr images (by setting non-generic user-agent)
- Layout tweaks

## v1.0.28

- Fix layout of extra wide attachments
- Swipe between attachments in gallery view

## v1.0.27

- Scroll to top

## v1.0.26

- Better thread-view layout

## v1.0.25

- Fix Profile picture url handling

## v1.0.24

- Single thread view

## v1.0.23

- Improve link preview
- Fix horizontal attachment scroll glitch
- Fix layout issue with iframs
- Fix layout issue with lists

## v1.0.22

- Fix crashing on Pixel 8a
- Refresh app icon
- Minor search improvement

## v1.0.21

- Shorter Profile bottom sheet
- Show RefreshSpinner more often
- Bump dependencies
- Refactor link parsing

## v1.0.20

- Attend/Flounce Event
- Clickable Profile chips on Events
- Fix Timezone issue on Events
- View attendees

## v1.0.19

- Edit comments
- Fix layout in search results
- Recognise links to comments in fragments
- Fix rendering of Events with no times

## v1.0.18

- Implement replies and mentions on updates screen
- Update tray background images
- Update dependencies
- Fix UI jank with vertical attachment layout
- Convert a bunch of stateful widgets to stateless
- Fix tapping on some search results

## v1.0.17

- Refactor Comment HTML rendering
- Fix Comments in search results with no highlighting
- Fix page numbering edge-case
- Fix "unread" dot for Huddles on Following screen

## v1.0.16

- Fix page number issue
- Handle "empty" comments better

## v1.0.15

- KeepAlive comments containing tweets
- Refresh main screens on navigation events
- Better rendering of Comments in search results
- Page dividers
- Better icon on Huddle tiles

## v1.0.14

- Fix link parsers
- Refresh profile bottom sheet

## v1.0.13

- Fix issue with Following page initial load
- Tweak primary colour in dark mode
- Tri-spoke for Huddle notifications
- Show avatars on Huddle tiles
- Slightly better internal link parsing
- Show last update timestamp on Huddle tiles, instead of created date
- Bump dependencies

## v1.0.12

- Select text & reply
- Profile selector
- LRU page cache

## v1.0.11

- Search
- Identify and render "x.com" tweets
- Show inline images in Gallery
- Fix: process Event URLs correctly
- Fix: "X time ago" render issue
- Fix: Show tooltip timestamps in local time

## v1.0.10

- Navigate to Conversation or Huddle after successful comment
- Improve New Comment UI
- Auto-refresh home pages on reactivate
- Default landing page for logged-in users is now "Following"
- Add context menu to Events and Huddles
- Overhaul Event header - include timezone calcs
- Add Huddle header - show participants
- Disable comment swiping on screens that don't support replies
- Overhaul of interface taxonomy

## v1.0.9

- Fix refresh behavior on a few pages
- Conversation context menu:
  - Share
  - Sub/Unsub

## v1.0.8

- Fix Huddles and Events
- Fix Tweet embedding edge-case

## v1.0.7

- Swipe to reply
- Fixed: refresh button becomes permanently unavailable
- Fixed: Comment title bar layout issues when too much text
- Relax Twitter link identification regex
- Slightly better notifications

## v1.0.6

- Embedded Tweets
- Text inputs capitalise by default now
- Fix formatting of "Reply to" names

## v1.0.5

- Conversation context menu:
  - Search in thread
  - Jump to page
  - Open in browser
