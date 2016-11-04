# -*- tab-width: 2 -*-
"use strict"

angular.module('memoire.controllers', ['memoire.services'])

.controller('QuickSearch', ($scope, $q, $state, Restangular) ->
  $scope.selected = null

  $scope.goTo = ($item, $model, $label) ->
    # Extract the id
    matches = $item.resource_uri.match(/\d+$/)
    if matches
      id = matches[0]

    if $item.resource_uri.search("production") != -1
      $state.go("artwork-detail", {id: id})

    else if $item.resource_uri.search("student") != -1
      $state.go("school.student", {id: id})


  $scope.search = (value) ->
    artworks = Restangular.all('production/artwork').customGET('search', {q: value}).then((response) ->
      return response.objects
    )

    students = Restangular.all('school/student').customGET('search', {q: value}).then((response) ->
      return response.objects
    )

    $q.all([students, artworks]).then((results) ->
      return _.flatten(_.map(results, _.values))
    )
)

.controller('ArtistListingController', ($scope, Artists, $state) ->
  $scope.letter = $state.params.letter || "a"
  $scope.artists = Artists.getList({user__last_name__istartswith: $scope.letter, limit: 200}).$object
  $scope.alphabet = "abcdefghijklmnopqrstuvwxyz".split("")
)

.controller('ArtworkListingController', ($scope, Artworks, $state) ->
  $scope.letter = $state.params.letter || "a"
  $scope.offset = parseInt($state.params.offset) || 0
  $scope.limit = 200
  $scope.artworks = Artworks.getList({title__istartswith: $scope.letter, limit: $scope.limit, offset:$scope.offset }).$object
  $scope.alphabet = "abcdefghijklmnopqrstuvwxyz".split("")
)

.controller('ArtworkGenreListingController', ($scope, Artworks, $state) ->
  $scope.genre = $state.params.genre || ""
  $scope.artworks = Artworks.getList({genres: $scope.genre, limit: 200}).$object
)


.controller('SchoolController', ($scope, $state, Promotions, Students) ->
  $scope.promotions = []

  Promotions.getList({order_by: "-starting_year"}).then((promotions) ->
    $scope.promotions = promotions
  )

)

.controller('PromotionController', ($scope, $stateParams, Students, Promotions) ->
  $scope.promotion = Promotions.one($stateParams.id).get().$object

  $scope.students = Students.getList({promotion: $stateParams.id, limit: 500}).$object
)

.controller('ArtistController', ($scope, $stateParams, Artists, Artworks) ->
  $scope.student = null
  $scope.artworks = []

  Artists.one().one($stateParams.id).get().then((artist) ->
    $scope.student = artist

    # Fetch artworks
    for artwork_uri in $scope.student.artworks
      matches = artwork_uri.match(/\d+$/)
      if matches
        artwork_id = matches[0]
        Artworks.one(artwork_id).get().then((artwork) ->
          $scope.artworks.push(artwork)
        )
  )
)

.controller('ArtworkController', ($scope, $stateParams, $sce, Lightbox, Artworks, AmeRestangular,  Events, Collaborators, Partners) ->
  $scope.artwork = null
  $scope.events = []


  $scope.main_picture_gallery = {media: []}
  # ame gallery vars for gallery
  $scope.ame_artwork_gallery = {media: []}
  # ame available for template
  $scope.ame_access = true

  Artworks.one().one($stateParams.id).get().then((artwork) ->
    $scope.artwork = artwork
    for event_uri in $scope.artwork.events
      matches = event_uri.match(/\d+$/)
      if matches
        event_id = matches[0]
        Events.one(event_id).get().then((event) ->
          $scope.events.push(event)
        )

    for collaborator_uri,key in $scope.artwork.collaborators
      if typeof collaborator_uri.match == Function
        matches = collaborator_uri.match(/\d+$/)
        if matches
          collaborator_id = matches[0]
          $scope.artwork.collaborators[key] = Collaborators.one(collaborator_id).get().$object


    for partner_uri,key in $scope.artwork.partners
      if typeof partner_uri.match == Function
        matches = partner_uri.match(/\d+$/)
        if matches
          partner_id = matches[0]
          $scope.artwork.partners[key] = Partners.one(partner_id).get().$object



    search = ""
    #return all artwork video and filtre with idFrezsnoy - TODO search idFresnoy in api
    AmeRestangular.all("api_search/").get("",{"search": search, "flvfile": "true", "previewsize":"scr"}).then((ame_artwork) ->
      for archive in ame_artwork
        # valid reference id Fresnoy => id AME

        if parseInt(archive.field201) == $scope.artwork.id

          if archive.flvpath

            $scope.ame_artwork_gallery.media.push({
              picture : archive.flvthumb
              medium_url : $sce.trustAsResourceUrl(archive.flvpath)
              description : archive.field8 #media ame title
           })

    , (response) ->
      #erreur service
      $scope.ame_access = false
    )
    # Fake a gallery for the main visual so we can reuse the gallery
    # component
    $scope.main_picture_gallery.media.push({
      picture: artwork.picture
      description: 'Visuel principal'
    })



  )

)

.controller('StudentController', ($scope, $stateParams, Students, Artworks, Promotions) ->
  $scope.student = null
  $scope.promotion = null
  $scope.artworks = []

  Students.one().one($stateParams.id).get().then((student) ->
    $scope.student = student

    # Fetch promotion
    matches = student.promotion.match(/\d+$/)
    if matches
      promotion_id = matches[0]
      Promotions.one(promotion_id).get().then((promotion) ->
        $scope.promotion = promotion
      )

    # Fetch artworks
    for artwork_uri in $scope.student.artworks
      matches = artwork_uri.match(/\d+$/)
      if matches
        artwork_id = matches[0]
        Artworks.one(artwork_id).get().then((artwork) ->
          $scope.artworks.push(artwork)
        )
  )
)


# Candidature Form

.controller('CandidatureFormController', ($scope, $q, $state, Restangular, ISO3166, Upload) ->


  # Birthdate minimum
  current_year = new Date().getFullYear()
  age_min = 25
  $scope.birthdateMin = new Date(current_year-age_min,11,31)

  #country
  $scope.countries = ISO3166.countryToCode

  #phone patterne
  $scope.phone_pattern = /^\+?\d{2}[-. ]?\d{9}$/

  #upload file
  $scope.upload_percentage = 0
  $scope.upload = (file) ->
    Upload.upload(
      {
        url: 'api.lefresnoy.net/utils/upload/',
        data: {
          file: file,
          name: $scope.username
        }
      }
    )
    .then((resp) ->
        console.log('Success ' + resp.config.data.file.name + ' uploaded');
        console.log(resp);
      ,(resp) ->
        console.log('Error status: ' + resp.status);
      ,(evt) ->
        $scope.upload_percentage = parseInt(100.0 * evt.loaded / evt.total);
        console.log('progress: ' + $scope.upload_percentage + '% ' + evt.config.data.file.name);
    )

  #adresse
  $scope.paOptions = {
  	updateModel : true
  }
  $scope.paTrigger = {}
  $scope.paDetails = {}
  $scope.placesCallback = (place) ->
    console.log("hello")

  #languages
  $scope.LANGUAGES = [{"alpha2":"aa","English":"Afar"},{"alpha2":"ab","English":"Abkhazian"},{"alpha2":"ae","English":"Avestan"},{"alpha2":"af","English":"Afrikaans"},{"alpha2":"ak","English":"Akan"},{"alpha2":"am","English":"Amharic"},{"alpha2":"an","English":"Aragonese"},{"alpha2":"ar","English":"Arabic"},{"alpha2":"as","English":"Assamese"},{"alpha2":"av","English":"Avaric"},{"alpha2":"ay","English":"Aymara"},{"alpha2":"az","English":"Azerbaijani"},{"alpha2":"ba","English":"Bashkir"},{"alpha2":"be","English":"Belarusian"},{"alpha2":"bg","English":"Bulgarian"},{"alpha2":"bh","English":"Bihari languages"},{"alpha2":"bi","English":"Bislama"},{"alpha2":"bm","English":"Bambara"},{"alpha2":"bn","English":"Bengali"},{"alpha2":"bo","English":"Tibetan"},{"alpha2":"br","English":"Breton"},{"alpha2":"bs","English":"Bosnian"},{"alpha2":"ca","English":"Catalan; Valencian"},{"alpha2":"ce","English":"Chechen"},{"alpha2":"ch","English":"Chamorro"},{"alpha2":"co","English":"Corsican"},{"alpha2":"cr","English":"Cree"},{"alpha2":"cs","English":"Czech"},{"alpha2":"cu","English":"Church Slavic; Old Slavonic; Church Slavonic; Old Bulgarian; Old Church Slavonic"},{"alpha2":"cv","English":"Chuvash"},{"alpha2":"cy","English":"Welsh"},{"alpha2":"da","English":"Danish"},{"alpha2":"de","English":"German"},{"alpha2":"dv","English":"Divehi; Dhivehi; Maldivian"},{"alpha2":"dz","English":"Dzongkha"},{"alpha2":"ee","English":"Ewe"},{"alpha2":"el","English":"Greek, Modern (1453-)"},{"alpha2":"en","English":"English"},{"alpha2":"eo","English":"Esperanto"},{"alpha2":"es","English":"Spanish; Castilian"},{"alpha2":"et","English":"Estonian"},{"alpha2":"eu","English":"Basque"},{"alpha2":"fa","English":"Persian"},{"alpha2":"ff","English":"Fulah"},{"alpha2":"fi","English":"Finnish"},{"alpha2":"fj","English":"Fijian"},{"alpha2":"fo","English":"Faroese"},{"alpha2":"fr","English":"French"},{"alpha2":"fy","English":"Western Frisian"},{"alpha2":"ga","English":"Irish"},{"alpha2":"gd","English":"Gaelic; Scottish Gaelic"},{"alpha2":"gl","English":"Galician"},{"alpha2":"gn","English":"Guarani"},{"alpha2":"gu","English":"Gujarati"},{"alpha2":"gv","English":"Manx"},{"alpha2":"ha","English":"Hausa"},{"alpha2":"he","English":"Hebrew"},{"alpha2":"hi","English":"Hindi"},{"alpha2":"ho","English":"Hiri Motu"},{"alpha2":"hr","English":"Croatian"},{"alpha2":"ht","English":"Haitian; Haitian Creole"},{"alpha2":"hu","English":"Hungarian"},{"alpha2":"hy","English":"Armenian"},{"alpha2":"hz","English":"Herero"},{"alpha2":"ia","English":"Interlingua (International Auxiliary Language Association)"},{"alpha2":"id","English":"Indonesian"},{"alpha2":"ie","English":"Interlingue; Occidental"},{"alpha2":"ig","English":"Igbo"},{"alpha2":"ii","English":"Sichuan Yi; Nuosu"},{"alpha2":"ik","English":"Inupiaq"},{"alpha2":"io","English":"Ido"},{"alpha2":"is","English":"Icelandic"},{"alpha2":"it","English":"Italian"},{"alpha2":"iu","English":"Inuktitut"},{"alpha2":"ja","English":"Japanese"},{"alpha2":"jv","English":"Javanese"},{"alpha2":"ka","English":"Georgian"},{"alpha2":"kg","English":"Kongo"},{"alpha2":"ki","English":"Kikuyu; Gikuyu"},{"alpha2":"kj","English":"Kuanyama; Kwanyama"},{"alpha2":"kk","English":"Kazakh"},{"alpha2":"kl","English":"Kalaallisut; Greenlandic"},{"alpha2":"km","English":"Central Khmer"},{"alpha2":"kn","English":"Kannada"},{"alpha2":"ko","English":"Korean"},{"alpha2":"kr","English":"Kanuri"},{"alpha2":"ks","English":"Kashmiri"},{"alpha2":"ku","English":"Kurdish"},{"alpha2":"kv","English":"Komi"},{"alpha2":"kw","English":"Cornish"},{"alpha2":"ky","English":"Kirghiz; Kyrgyz"},{"alpha2":"la","English":"Latin"},{"alpha2":"lb","English":"Luxembourgish; Letzeburgesch"},{"alpha2":"lg","English":"Ganda"},{"alpha2":"li","English":"Limburgan; Limburger; Limburgish"},{"alpha2":"ln","English":"Lingala"},{"alpha2":"lo","English":"Lao"},{"alpha2":"lt","English":"Lithuanian"},{"alpha2":"lu","English":"Luba-Katanga"},{"alpha2":"lv","English":"Latvian"},{"alpha2":"mg","English":"Malagasy"},{"alpha2":"mh","English":"Marshallese"},{"alpha2":"mi","English":"Maori"},{"alpha2":"mk","English":"Macedonian"},{"alpha2":"ml","English":"Malayalam"},{"alpha2":"mn","English":"Mongolian"},{"alpha2":"mr","English":"Marathi"},{"alpha2":"ms","English":"Malay"},{"alpha2":"mt","English":"Maltese"},{"alpha2":"my","English":"Burmese"},{"alpha2":"na","English":"Nauru"},{"alpha2":"nb","English":"Bokmål, Norwegian; Norwegian Bokmål"},{"alpha2":"nd","English":"Ndebele, North; North Ndebele"},{"alpha2":"ne","English":"Nepali"},{"alpha2":"ng","English":"Ndonga"},{"alpha2":"nl","English":"Dutch; Flemish"},{"alpha2":"nn","English":"Norwegian Nynorsk; Nynorsk, Norwegian"},{"alpha2":"no","English":"Norwegian"},{"alpha2":"nr","English":"Ndebele, South; South Ndebele"},{"alpha2":"nv","English":"Navajo; Navaho"},{"alpha2":"ny","English":"Chichewa; Chewa; Nyanja"},{"alpha2":"oc","English":"Occitan (post 1500); Provençal"},{"alpha2":"oj","English":"Ojibwa"},{"alpha2":"om","English":"Oromo"},{"alpha2":"or","English":"Oriya"},{"alpha2":"os","English":"Ossetian; Ossetic"},{"alpha2":"pa","English":"Panjabi; Punjabi"},{"alpha2":"pi","English":"Pali"},{"alpha2":"pl","English":"Polish"},{"alpha2":"ps","English":"Pushto; Pashto"},{"alpha2":"pt","English":"Portuguese"},{"alpha2":"qu","English":"Quechua"},{"alpha2":"rm","English":"Romansh"},{"alpha2":"rn","English":"Rundi"},{"alpha2":"ro","English":"Romanian; Moldavian; Moldovan"},{"alpha2":"ru","English":"Russian"},{"alpha2":"rw","English":"Kinyarwanda"},{"alpha2":"sa","English":"Sanskrit"},{"alpha2":"sc","English":"Sardinian"},{"alpha2":"sd","English":"Sindhi"},{"alpha2":"se","English":"Northern Sami"},{"alpha2":"sg","English":"Sango"},{"alpha2":"si","English":"Sinhala; Sinhalese"},{"alpha2":"sk","English":"Slovak"},{"alpha2":"sl","English":"Slovenian"},{"alpha2":"sm","English":"Samoan"},{"alpha2":"sn","English":"Shona"},{"alpha2":"so","English":"Somali"},{"alpha2":"sq","English":"Albanian"},{"alpha2":"sr","English":"Serbian"},{"alpha2":"ss","English":"Swati"},{"alpha2":"st","English":"Sotho, Southern"},{"alpha2":"su","English":"Sundanese"},{"alpha2":"sv","English":"Swedish"},{"alpha2":"sw","English":"Swahili"},{"alpha2":"ta","English":"Tamil"},{"alpha2":"te","English":"Telugu"},{"alpha2":"tg","English":"Tajik"},{"alpha2":"th","English":"Thai"},{"alpha2":"ti","English":"Tigrinya"},{"alpha2":"tk","English":"Turkmen"},{"alpha2":"tl","English":"Tagalog"},{"alpha2":"tn","English":"Tswana"},{"alpha2":"to","English":"Tonga (Tonga Islands)"},{"alpha2":"tr","English":"Turkish"},{"alpha2":"ts","English":"Tsonga"},{"alpha2":"tt","English":"Tatar"},{"alpha2":"tw","English":"Twi"},{"alpha2":"ty","English":"Tahitian"},{"alpha2":"ug","English":"Uighur; Uyghur"},{"alpha2":"uk","English":"Ukrainian"},{"alpha2":"ur","English":"Urdu"},{"alpha2":"uz","English":"Uzbek"},{"alpha2":"ve","English":"Venda"},{"alpha2":"vi","English":"Vietnamese"},{"alpha2":"vo","English":"Volapük"},{"alpha2":"wa","English":"Walloon"},{"alpha2":"wo","English":"Wolof"},{"alpha2":"xh","English":"Xhosa"},{"alpha2":"yi","English":"Yiddish"},{"alpha2":"yo","English":"Yoruba"},{"alpha2":"za","English":"Zhuang; Chuang"},{"alpha2":"zh","English":"Chinese"},{"alpha2":"zu","English":"Zulu"}]

  #cursus
  $scope.cursus = {}
  $scope.cursus.items = []
  $scope.addCursus = ->
      $scope.cursus.items.push({
        inlineChecked: false,
        question: "",
        questionPlaceholder: "foo",
        text: ""
      });

  $scope.removeCursus = (item) ->
    del item





  #update
  $scope.update = (user, form) ->

    console.log(form)
    #console.log(form.uPhoto)
    $scope.infos = angular.copy(user);
    return true





)
