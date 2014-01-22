##
##    @module: ezimage
##    @author: Jason Wijegooneratnes
##    @created: 05 Jan 2014
##    @requires: jQuery 1.10+, BlueImp jQuery File Upload
##
##    A simple image insert/select plugin for Hallo JS. It uses BlueImp's jQuery File Upload to handle checked
##    uploading so be sure to set this up properly (see https://github.com/blueimp/jQuery-File-Upload for info).    
##
##   @options (OBJ):
##       uploadURL (STR): The upload path for the image. Should point to jQuery File Uploader server side script
##       fetchURL (STR): The url for fetching a list of images available for selection. Expects a JSON response
##                       like this - { 'image_url', 'image_url', 'image_url', 'image_url' }
##
######################
######################


((jQuery) ->
  jQuery.widget "IKS.halloezimage",
    # some commonly used vars
    dialog: null
    dialogId: null
    # cached elements
    pbar: null
    # widget options
    options:
      uuid: ''
      # the editable element in focus
      editable: null
      # the image upload endpoint for the widget.
      uploadURL: ''
      # the image fetch endpoint for this url.
      fetchURL: ''
      # the title for this widget's menu button. set default.
      label: 'Insert Image'
      imageClass: 'halloimage'
      # an optional context pareter to be passed to the server side uplaod script
      context: null

    # constructor fn.
    _create: () ->
      # create the insert/select dialog box
      widget = @

      # if dialog has not been set do so.
      if @dialog is null
        @dialogId = @options.uuid + "-image-dialog"

        # create dialog box for insert/select image
        @dialog = jQuery "<div class='ezimage-widget' id='#{@dialogId}'>
            <ul class='eztabs'>
              <li><a href='##{@options.uuid}-tab-upload'>Insert</a></li>
              <li><a href='##{@options.uuid}-tab-select'>Select</a></li>
            </ul>
            <div id='#{@options.uuid}-tab-upload'>
              <form>
                <input type='file' id='#{@options.uuid}-ezfile' name='files[]' accept='image/*' multiple/>
                <div class='progress-bar'></div>
              </form>
            </div>
            <div id='#{@options.uuid}-tab-select'>
            </div>
          </div>
          "
        # append dialog to the document
        jQuery( 'body' ).append @dialog
        
        # setup dialogs internal tabz. When 'SELECT' is pressed call should be made to populate images
        jQuery( '#' + widget.dialogId ).tabs({
            'activate' : ( event, ui ) ->
              targetTab = ui.newTab.find('a')
              targetPanel = ui.newPanel

              # filter for SELECT tab. Populate with images if found
              if targetTab.text() is "Select" then widget.fetchImages targetPanel
          })

        # set file select event
        @setupUploader @dialog

        # set & hide progress bar
        @pbar = @dialog.find('.progress-bar')
        # @pbar.progressbar()
        @pbar.hide()

        # dialog is hidden on init
        @dialog.hide()
        # hide progress bar

    # fn sets up the BLUEIMP jQuery File Uploader and integrates it with this widget
    # @elem (jQuery): The widget container element as a jQuery object.
    setupUploader: ( elem ) ->
      # cache options var for reference
      opts = @options
      target = @options.uuid + '-ezfile'
      widget = @

      # use BLUEIMP jQuery File Uploader to handle chunked uploading
      elem.find( '#' +  target ).fileupload({
          # the upload URL and its expected datatype set to JSON
          url : opts.uploadURL
          dataType : 'json'
          formData: { 'context' : widget.options.context }
          # fn called when upload succesfully completes
          done: ( e, data ) ->
            # iterate file uploads and append them to document
            jQuery.each data.result.files, (index, file) ->
                # get file url and append it to editable element at the cursor
                furl = file.url
                widget.insertImageContent furl

            # close the widget
            widget.toggleWidget()

            # hide & reset progress bar
            # widget.pbar.progressbar( "value", 0 )
            widget.pbar.text("0 %");
            widget.pbar.hide()
          
          # called on start of fileupload to make things look pretty
          start: ( e, data ) ->
            widget.pbar.show()

          # fn called on upload error. will output some debug info
          fail: ( e, data ) ->
            # output debug
            # console.log "debug info: ", data.textStatus, data.jqXHR
            # close the widget
            widget.toggleWidget()
            
             # hide & reset progress bar
            widget.pbar.text("0 %");
            widget.pbar.hide()

          # fn called to update progress data
          progressall: ( e, data ) ->
            progress = parseInt(data.loaded / data.total * 100, 10);
            widget.pbar.text( progress + "%");
      })
    
    # fn fetches images from the fetchURL endpoint
    # @target (jQuery): The target container for the images as a jQuery object.
    fetchImages: ( target ) ->
      widget = @
      # do ajax request @ fetchURL
      jQuery.ajax( @options.fetchURL, {
            complete: ( e, jqXHR, textStatus ) ->
              # parse JSON response
              data = jQuery.parseJSON( e.responseText )
              # set available images
              widget.setSelectableImages data, target
      })

    # fn populates the image select tab with the available images
    # @data (ARRAY): An array of image URL's that are to be made available to the user
    # @target (jQuery): The target container for the images as a jQuery object. In this case the tab display container.
    setSelectableImages: ( data, target ) ->
      widget = @

      # clear cached html content
      target.html('')

      # filter that we actually have data
      if data.length > 0
        # iterate available images and add to selection box
        jQuery.each data, ( index, imgData ) ->
          img_url = imgData['url'];
          img_alt = imgData['alt'];

          # create img as jQ object and append to selection box
          img = jQuery "<img src='#{img_url}' alt='#{img_alt}' class='thumbnail' />"
          target.append img

          # create a click event for this image to append to document
          img.on 'click', ( event, ui ) ->
            # do insert
            img_src = jQuery(this).attr('src')
            widget.insertImageContent img_src
      else
        target.append "<small>no images available yet</small>"

    # fn handles inserting images into content
    # @furl (STR): The image (file) URL as a string
    insertImageContent: ( furl ) ->
        widget = @
        # generate a unique DOM ID for this image
        uid = @options.uuid + '-' + (Math.random() * 100).toString().replace('.', '') + '-' + (Math.random() * 100).toString().replace('.', '') + '-' + 'image-insert'
        # build its HTML string. add a default class to apply and its uuid for later reference
        imgHTML = "<img src='#{furl}' id='#{uid}' class='#{@options.imageClass}' />"
        # use execCmd insertHTML instead of insertImage so that we can set its class etc
        # document.execCommand "insertHTML", null, imgHTML
        jQuery(@element).focus();
        pasteHtmlAtCaret(imgHTML);
        # console.log(widget.element)
       #  jQuery( widget.element ).insertText( imgHTML, 0 )
        # return generated uuid of image in case we want to operate on it
        return uid


    # fn creates the widgets tollbar entry
    # @toolbar (jQuery): The Hallo JS menu toolbar as a jQuery object
    populateToolbar: (toolbar) ->
      # Create an element for holding the button
      @buttonElement = jQuery '<span></span>'

      # Use Hallo Button
      @buttonElement.hallobutton
        uuid: @options.uuid
        editable: @options.editable
        # the button label
        label: @options.label
        # the icon to use
        icon: 'icon-picture'
        # no cmd to execute
        command: null

      # setup insert events
      @setMenuClickEvent( @buttonElement )

      # Append the button to toolbar
      toolbar.append @buttonElement

    # fn creates menu btn click event
    # @btn (jQuery): The widgets menu button as a jQuery object
    setMenuClickEvent: (btn) ->
      # set widget equal to 'this' object so we can reference it from the click event
      widget = @

      # create click event for the button
      btn.on 'click', (event)->
        # show the dialog
        widget.positionWidet()   
        widget.toggleWidget()


    # positions the widget next to its menu button
    positionWidet: ->
      # get button position via jQuery API
      btn_pos = @buttonElement.offset()
      btn_height = @buttonElement.height()

      # cache top/left values
      btn_top = btn_pos.top
      btn_left = btn_pos.left

      @dialog.css({
        'position' : 'absolute',
        'top' : btn_top + btn_height + 20,
        'left' : btn_left 
      })

    # toggle the widgets visability on/off. also toggles the autoclose feature of jquery ui widgets
    toggleWidget: ->
      if @options.editable._keepActivated is false
        @dialog.show()
        @options.editable.keepActivated true
        return
      else
        @dialog.hide()
        @options.editable.keepActivated false
        return


    # clean stuff up when editable is out of focus
    cleanupContentClone: () ->
      # hide it and set keed activated to fasle
      @options.editable.keepActivated false
      @dialog.hide()

)(jQuery)