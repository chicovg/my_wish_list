var GetWishListLink = function() {};

GetWishListLink.prototype = {
    run : function(arguments) {
        arguments.completionFunction({ "documentUrl" : document.URL });
    }
};

var ExtensionPreprocessingJS = new GetWishListLink;