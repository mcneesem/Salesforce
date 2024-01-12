({
	showSpinner : function(cmp,spinnerId) {
		setTimeout( $A.getCallback(function(){
			$A.util.removeClass(cmp.find(spinnerId),'slds-hide');
		}),0);
	},
	hideSpinner : function(cmp,spinnerId) {
		setTimeout( $A.getCallback(function(){
			$A.util.addClass(cmp.find(spinnerId),'slds-hide');
		}),0);
	}
})