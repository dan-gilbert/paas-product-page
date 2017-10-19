$(function(){

	var stepStack = [];

	function currentStep() {
		if (stepStack.length == 0) {
			return null;
		}
		return $(stepStack[stepStack.length-1]);
	}

	function setStep(selector) {
		var current = currentStep();
		if (current) {
			if (showErrors(current)){
				return;
			}
		}
		$('.step').hide();
		$(selector).show();
		stepStack.push(selector);
	}

	function clickStepButton(e) {
		if (e && e.preventDefault) {
			e.preventDefault();
		}
		var nextSelector = '.' + $(this).parents('.step').find('input[name=step]:checked,input[type=hidden][name=step]').val();
		setStep(nextSelector);
	}

	function clickStepBack(e) {
		if (e && e.preventDefault) {
			e.preventDefault();
		}
		stepStack.pop();
		var prevSelector = stepStack.pop();
		if (prevSelector) {
			console.log(prevSelector);
			setStep(prevSelector);
		} else {
			window.location.href = $(this).attr('href');
		}
	}

	function toggleInviteRadio() {
		var table = $('#invite-table');
		var checked = $('#invite-radio-yes').is(':checked');
		if (checked) {
			table.show();
		} else {
			table.hide();
		}
	}

	function toggleIsManagerRadio() {
		var note = $('#person-is-manager-no--note');
		var checked = $('#person-is-manager-no').is(':checked');
		if (checked) {
			note.show();
		} else {
			note.hide();
		}
	}

	function focusField(e) {
		if (e && e.preventDefault) {
			e.preventDefault();
			e.stopPropagation();
		}
		var field = $('[name=' + $(this).data('field') + ']');
		if (field.length > 0) {
			setTimeout(function(){
				field.first().focus();
			}, 0);
		}
	}

	function isBlank(v) {
		return !v || /^\s+$/.test(v);
	}

	function isValidEmail(v) {
		return v && /.+@.+/.test(v);
	}

	function isGovEmail(v) {
		return v && /.gov.uk/.test(v);
	}

	function getFormError(name, value) {
		if (!name) {
			return;
		} else if (name === 'person_name') {
			if (isBlank(value)) {
				return 'Name cannot be blank';
			}
		} else if (name == 'person_email') {
			if (isBlank(value)) {
				return 'Email address cannot be blank';
			}
			if (!isValidEmail(value)) {
				return 'Must be a valid email address';
			}
			if (!isGovEmail(value)) {
				return 'We can only accept requests from .gov.uk email addresses';
			}
		} else if (name == 'department_name') {
			if (isBlank(value)) {
				return 'Department name cannot be blank';
			}
		} else if (name == 'service_name') {
			if (isBlank(value)) {
				return 'Service name cannot be blank';
			}
		}
	}

	function getFormErrors(parent) {
		var errs = {};
		parent.find('.form-control').each(function(i, el){
			var field = $(el);
			var name = field.attr('name');
			var value = field.val();
			var err = getFormError(name, value);
			if (err) {
				errs[name] = err;
			}
		});
		return errs;
	}

	function showErrors(parent) {
		parent.find('.form-group-error').removeClass('form-group-error');
		parent.find('.step-button').removeAttr('disabled');
		var errs = getFormErrors(parent);
		var hasErrors = false;
		for (var k in errs) {
			var group = parent.find('input[name=' + k + ']').parents('.form-group');
			group.addClass('form-group-error');
			group.find('.error-message').text(errs[k]);
			hasErrors = true;
			console.log('err', k, errs[k]);
		}
		return hasErrors;
	}

	function init() {
		var hasErrors = $('.form-group-error, .error-summary').length > 0;

		// setup event handlers
		$('.step-button').click(clickStepButton);
		$('.step-back').click(clickStepBack);
		$('.invite-radio').change(toggleInviteRadio);
		$('.person-is-manager').change(toggleIsManagerRadio)
		$('.focus-field').click(focusField);

		// trigger initial state
		setStep('.step--start');
		toggleInviteRadio();
		toggleIsManagerRadio();

		// if there are any errors then expand all form sections
		// otherwise show the step buttons
		if (hasErrors) {
			$('.step--all').show();
			$('.form-group-error :input:visible').first().focus();
			$('.step-button').attr('disabled', 'disabled');
		} else {
			$('.step-button').show();
			$('.step-button').removeAttr('disabled');
		}
	}

	init();
});
