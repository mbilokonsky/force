cheerio = require 'cheerio'
fs = require 'fs'
jade = require 'jade'
path = require 'path'
Backbone = require 'backbone'
{ fabricate } = require 'antigravity'
Artwork = require '../../../models/artwork'
Artists = require '../../../collections/artists'
Artist = require '../../../models/artist'
SaleArtwork = require '../../../models/sale_artwork'

render = (template) ->
  filename = path.resolve __dirname, "../templates/#{template}.jade"
  jade.compile(
    fs.readFileSync(filename),
    { filename: filename }
  )

describe 'Artwork Item template', ->

  describe 'artwork item image', ->
    beforeEach ->
      @artwork = new Artwork fabricate 'artwork'

    it 'defaults to a medium size artwork image', ->
      $ = cheerio.load render('artwork')({ artwork: @artwork })
      $('img').attr('src').should.containEql 'medium'

    it 'can render a specified size', ->
      $ = cheerio.load render('artwork')({ artwork: @artwork, artworkSize: 'large' })
      $('img').attr('src').should.containEql 'large'

    it 'renders with a fixed with', ->
      $ = cheerio.load render('artwork')({ artwork: @artwork, imageWidth: 500 })
      $('img').attr('width').should.equal '500'
      $('img').attr('height').should.equal '250'
      $('img').attr('src').should.containEql 'medium'

    it 'falls back to an uncropped size', ->
      @artwork.defaultImage().set 'image_versions', ['tall', 'medium']
      $ = cheerio.load render('artwork')({ artwork: @artwork, artworkSize: 'large' })
      $('img').attr('src').should.containEql 'tall'

    it 'allows arrays in artworkSize and falls back on array', ->
      @artwork.defaultImage().set 'image_versions', ['tall', 'medium']
      $ = cheerio.load render('artwork')({ artwork: @artwork, artworkSize: ['large', 'medium'] })
      $('img').attr('src').should.containEql 'medium'

  describe 'artwork caption', ->
    beforeEach ->
      @artwork = new Artwork fabricate 'artwork'
      @artist = new Artist fabricate 'artist'
      @artist2= new Artist fabricate 'artist', {name: 'Kana', public: true}
      @artwork.related().artists = new Artists @artist
      @html = render('artwork')({ artwork: @artwork })

    it 'displays the artwork title and year', ->
      $ = cheerio.load @html
      $('.artwork-item-title em').text().should.equal @artwork.get 'title'
      $('.artwork-item-title').html().should.equal @artwork.titleAndYear()

    it 'displays the artist name if available', ->
      $ = cheerio.load @html
      $('.artwork-item-artist').text().should.equal @artist.displayName()
      $('.artwork-item-artist a').should.have.lengthOf 0

    it 'displays multiple artists if there are any', ->
      @artwork.related().artists = new Artists [@artist, @artist2]
      @artist.set 'public', true
      $ = cheerio.load render('artwork')({ artwork: @artwork })
      $('.artwork-item-artist').text().should.equal 'Pablo PicassoKana'
      $('.artwork-item-artist a').should.have.lengthOf 2

    it 'links to the artist if it\'s public', ->
      @artist.set 'public', true
      $ = cheerio.load render('artwork')({ artwork: @artwork })
      $('.artwork-item-artist a').text().should.equal @artist.displayName()
      $('.artwork-item-artist a').attr('href').should.equal @artist.href()

    it 'links to the partner name', ->
      @artwork.get('partner').default_profile_public = true
      @artwork.get('partner').default_profile_id = 'moma'
      $ = cheerio.load render('artwork')({ artwork: @artwork })
      $('.artwork-item-partner a').should.have.lengthOf 1
      $('.artwork-item-partner a').text().should.equal @artwork.partnerName()
      $('.artwork-item-partner a').attr('href').should.equal @artwork.partnerLink()

    it 'displays a sale message', ->
      @artwork.set
        sale_message: "$5,200"
        forsale: true
      $ = cheerio.load render('artwork')({ artwork: @artwork })
      $('.artwork-item-sale-price').text().should.equal @artwork.get 'sale_message'

    it 'displays a sale message if artwork is not for sale', ->
      @artwork.set
        sale_message: "$5,200"
        forsale: false
      $ = cheerio.load render('artwork')({ artwork: @artwork })
      $('.artwork-item-sale-price').length.should.equal 1

  describe 'nopin', ->
    beforeEach ->
      @artwork = new Artwork fabricate 'artwork'
      @html = render('artwork')({ artwork: @artwork })


    it 'renders a nopin attribute if the artwork is not sharable', ->
      @artwork.set 'can_share_image', false
      $ = cheerio.load render('artwork')({ artwork: @artwork })
      $('img').attr('nopin').should.equal 'nopin'

    it 'does not render a nopin attribute if the artwork is sharable', ->
      @artwork.set 'can_share_image', true
      $ = cheerio.load render('artwork')({ artwork: @artwork })
      $('img[nopin]').should.have.lengthOf 0

  describe 'blurb', ->

    it 'renders a blurb when the artwork has one and is part of a sale', ->
      @artwork = new Artwork fabricate 'artwork'
      $ = cheerio.load render('artwork')({ artwork: @artwork })
      $('.artwork-item-blurb').should.have.lengthOf 0

      @artwork.set 'blurb', 'This is the blurb'
      $ = cheerio.load render('artwork')({ artwork: @artwork })
      $('.artwork-item-blurb').should.have.lengthOf 0

      @artwork.related().saleArtwork = new SaleArtwork fabricate 'sale_artwork'
      $ = cheerio.load render('artwork')({ artwork: @artwork })
      $('.artwork-item-blurb').should.have.lengthOf 1
      $('.artwork-item-blurb').text().should.containEql 'This is the blurb'

  describe 'buy button', ->

    it 'renders a buy button if the work is acquirable and purchase is allowed', ->
      @artwork = new Artwork fabricate 'artwork', { acquireable: true }
      $ = cheerio.load render('artwork')({ artwork: @artwork })
      $('.artwork-item-buy').should.have.lengthOf 0

      $ = cheerio.load render('artwork')({ artwork: @artwork, displayPurchase: true })
      $('.artwork-item-buy').should.have.lengthOf 1

  describe 'sold', ->

    it 'renders a sold message if the work is sold and purchase is allowed', ->
      @artwork = new Artwork fabricate 'artwork', { sold: true }
      $ = cheerio.load render('artwork')({ artwork: @artwork })
      $('.artwork-item-sold').should.have.lengthOf 0

      $ = cheerio.load render('artwork')({ artwork: @artwork, displayPurchase: true })
      $('.artwork-item-sold').should.have.lengthOf 1

  describe 'is auction', ->
    it 'displays a buy now price', ->
      @artwork = new Artwork fabricate 'artwork', { sale_message: '$10,000' }
      @artwork.set 'sale_artwork', fabricate 'sale_artwork'
      $ = cheerio.load render('artwork')({ artwork: @artwork, isAuction: true })
      $('.artwork-item-buy-now-price').text().should.containEql '$10,000'

    it 'displays estimate', ->
      @artwork = new Artwork fabricate 'artwork'
      @artwork.set 'sale_artwork', fabricate 'sale_artwork', { display_low_estimate_dollars: '$3,000', display_high_estimate_dollars: '$7,000' }
      $ = cheerio.load render('artwork')({ artwork: @artwork, isAuction: true })
      $('.artwork-item-estimate').text().should.containEql 'Estimate: $3,000–$7,000'

    it 'displays lot numbers', ->
      @artwork = new Artwork fabricate 'artwork'
      @artwork.set 'sale_artwork', fabricate 'sale_artwork',
        { low_estimate_cents: 300000, high_estimate_cents: 700000, lot_number: 10 }
      $ = cheerio.load render('artwork')({ artwork: @artwork, isAuction: true })
      $('.artwork-item-lot-number').text().should.containEql 'Lot 10'

  describe 'contact button', ->
    it 'says "Contact Gallery"', ->
      @artwork = new Artwork fabricate 'artwork', forsale: true
      $ = cheerio.load render('artwork')(artwork: @artwork, displayPurchase: true)
      $('.artwork-item-contact-seller').text().should.equal 'Contact Gallery'
