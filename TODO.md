Figure out how to show multiple place model results on 1 places_map_container (eg amenities and campgrounds)

Allow people to contribute cell information:
  - https://github.com/Esri/cordova-plugin-advanced-geolocation
  - Get carrier, band, strength, maybe download speed?

no- embed distance when getting nearby amenities? and cache for a while?
  no- problem is can't query based on that
- any time an amenity is added, get all campgrounds w/in 100mi (crow fly)
    - filter out any campgrounds where nearest amenity
      driving is < crow fly distance
    - get route for the remainder, filter any where nearest
      amenity driving < route distance
    - update db for any that remain
- any time campground is added, get all amenities w/in 100mi?
  or just closest x using getAmenityBoundsById
- campground: {closestAmenities: {dump: {distance: 32, time: 30}}}

- Edit review use initial season for value?
- Ask for rig information on first review
x Tooltip picture and reviews
- Swipe / tap through gallery of images
- "We don't have any data for this season yet, but here\'s what it was like in *season*"
- no reviews -> loading
- pad types, mark seasonal campgrounds (checkbox when creating + dates its open / link)
- compress images before upload
- Mark low overhangs, sharp turns
- Add gyms
x overlay$ -> model. get all overlay, sheet, dialog components
x method to input sliders for other seasons w/o adding review score
x 4g/3g toggle for signal
x coordinates from images
x tags for images
x Link to instagram, website, etc.. from review
x Cell signals
x Get reviews working / updating place score
x View review images full-size
x Add filters
x force at least 1 star
- Map doesn't show after locking and unlocking phone?
  - probably webgl losing context https://github.com/mapbox/mapbox-gl-js/issues/2656
  - can plugin to inspect after it happens?
- Don't load nearby map until tab is active
x Add review redirect back to reviews
x Reviews add to photos
x Show photos on place page


Feedback:
- Maybe 'nearby' is hard to get to? Seems like some people never see it
- Map of places you've been. Roads you traveled would be cool too, if possible


- Update Google Play & iOS descriptions
- Onboarding in chat. The community for Boondockers
- "Find me a WALMART!", maybe some people-of-walmart personality here while it's loading
- Nearest dump, fresh water
- Find campgrounds YouTubers have been to, link videos, Instagram posts?
  - Ask YouTuber if it's alright if we link to video from the page, explain FreeRoam

---

Things people want
- Ways to make money on road
- Better trip / gas station tools (ones out there are pretty decent though)
- To promote their instagram, website, etc...

Maybe a social profile that brings in YouTube videos, Instagram, map of where they've been, products they use
  - Don't think Instagram's API even lets us grab pics

- Need a better onboarding experience, introducing to vision

Boondocking
- Nearby dumpsites, freshwater, ...

Other feedback
- partners page, link to people's social media, etc...
  - application process, minimum number of followers
  - sort by most followers

- route planner that takes into account RV height
- truck / trailer finder by weight, truck towing capacities
- finding RV-friendly gas stations for gas
