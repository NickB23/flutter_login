part of auth_card_builder;

class _RecoverCard extends StatefulWidget {
  const _RecoverCard(
      {Key? key,
      required this.userValidator,
      required this.onBack,
      required this.userType,
      this.recoverFields,
      this.loginTheme,
      required this.navigateBack,
      required this.onSubmitCompleted,
      required this.loadingController})
      : super(key: key);

  final FormFieldValidator<String>? userValidator;
  final Function onBack;
  final LoginUserType userType;
  final List<UserFormField>? recoverFields;
  final LoginTheme? loginTheme;
  final bool navigateBack;
  final AnimationController loadingController;

  final Function onSubmitCompleted;

  @override
  _RecoverCardState createState() => _RecoverCardState();
}

class _RecoverCardState extends State<_RecoverCard>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formRecoverKey = GlobalKey();

  bool _isSubmitting = false;

  late TextEditingController _nameController;

  late AnimationController _submitController;

  @override
  void initState() {
    super.initState();

    final auth = Provider.of<Auth>(context, listen: false);
    _nameController = TextEditingController(text: auth.email);
    if (widget.recoverFields != null) {
      List<UserFormField> formFields = widget.recoverFields!;
      _nameControllers =
          HashMap<String, TextEditingController>.fromIterable(formFields,
              key: (formFields) => formFields.keyName,
              value: (formFields) => TextEditingController(
                    text: formFields.defaultValue,
                  ));

      if (_nameControllers.length != formFields.length) {
        throw ArgumentError(
            'Some of the formFields have duplicated names, and this is not allowed.');
      }
    }

    _submitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _submitController.dispose();
    super.dispose();
  }

  Future<bool> _submit() async {
    if (!_formRecoverKey.currentState!.validate()) {
      return false;
    }
    final auth = Provider.of<Auth>(context, listen: false);
    final messages = Provider.of<LoginMessages>(context, listen: false);

    _formRecoverKey.currentState!.save();
    await _submitController.forward();
    setState(() => _isSubmitting = true);
    String? error;
    // ToDo: use single onRecoverPassword on version 4.0
    if (widget.recoverFields != null) {
      auth.customRecoverData =
          _nameControllers.map((key, value) => MapEntry(key, value.text));
      error = await auth.onRecoverPasswordCustom!(
          RecoverData(customRecoverData: auth.customRecoverData));
    } else {
      error = await auth.onRecoverPassword!(auth.email);
    }

    if (error != null) {
      showErrorToast(context, messages.flushbarTitleError, error);
      setState(() => _isSubmitting = false);
      await _submitController.reverse();
      return false;
    } else {
      showSuccessToast(context, messages.flushbarTitleSuccess,
          messages.recoverPasswordSuccess);
      setState(() => _isSubmitting = false);
      widget.onSubmitCompleted();
      return true;
    }
  }

  Widget _buildRecoverNameField(
      double width, LoginMessages messages, Auth auth) {
    return AnimatedTextFormField(
      controller: _nameController,
      loadingController: widget.loadingController,
      width: width,
      labelText: messages.userHint,
      prefixIcon: const Icon(FontAwesomeIcons.solidUserCircle),
      keyboardType: TextFieldUtils.getKeyboardType(widget.userType),
      autofillHints: [TextFieldUtils.getAutofillHints(widget.userType)],
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (value) => _submit(),
      validator: widget.userValidator,
      onSaved: (value) => auth.email = value!,
    );
  }

  Widget _buildRecoverButton(ThemeData theme, LoginMessages messages) {
    return AnimatedButton(
      controller: _submitController,
      text: messages.recoverPasswordButton,
      onPressed: !_isSubmitting ? _submit : null,
    );
  }

  Widget _buildBackButton(
      ThemeData theme, LoginMessages messages, LoginTheme? loginTheme) {
    final calculatedTextColor =
        (theme.cardTheme.color!.computeLuminance() < 0.5)
            ? Colors.white
            : theme.primaryColor;
    return MaterialButton(
      onPressed: !_isSubmitting
          ? () {
              _formRecoverKey.currentState!.save();
              widget.onBack();
            }
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textColor: loginTheme?.switchAuthTextColor ?? calculatedTextColor,
      child: Text(messages.goBackButton),
    );
  }

  late HashMap<String, TextEditingController> _nameControllers;

  Widget _buildCustomRecoverFields(double width) {
    List<UserFormField> formFields = [];
    if (widget.recoverFields == null) {
      return Container();
    } else {
      formFields = widget.recoverFields!;
    }
    return Column(
        children: formFieldsBuilder(
            formFields, _nameControllers, width, widget.loadingController));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Provider.of<Auth>(context, listen: false);
    final messages = Provider.of<LoginMessages>(context, listen: false);
    final deviceSize = MediaQuery.of(context).size;
    final cardWidth = min(deviceSize.width * 0.75, 360.0);
    const cardPadding = 16.0;
    final textFieldWidth = cardWidth - cardPadding * 2;

    return FittedBox(
      child: Card(
        child: Container(
          padding: const EdgeInsets.only(
            left: cardPadding,
            top: cardPadding + 10.0,
            right: cardPadding,
            bottom: cardPadding,
          ),
          width: cardWidth,
          alignment: Alignment.center,
          child: Form(
            key: _formRecoverKey,
            child: Column(
              children: [
                Text(
                  messages.recoverPasswordIntro,
                  key: kRecoverPasswordIntroKey,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyText2,
                ),
                const SizedBox(height: 20),
                widget.recoverFields == null
                    ? _buildRecoverNameField(textFieldWidth, messages, auth)
                    : _buildCustomRecoverFields(textFieldWidth),
                const SizedBox(height: 20),
                Text(
                  auth.onConfirmRecover != null
                      ? messages.recoverCodePasswordDescription
                      : messages.recoverPasswordDescription,
                  key: kRecoverPasswordDescriptionKey,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyText2,
                ),
                const SizedBox(height: 26),
                _buildRecoverButton(theme, messages),
                _buildBackButton(theme, messages, widget.loginTheme),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
