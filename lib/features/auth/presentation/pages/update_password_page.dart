import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rides365/common/app_constants.dart';
// ignore: unused_import
import 'package:rides365/core/model/user_detail_model.dart';

import '../../../../common/common.dart';
import '../../../../core/utils/custom_background.dart';
import '../../../../core/utils/custom_button.dart';
import '../../../../core/utils/custom_loader.dart';
import '../../../../core/utils/custom_text.dart';
import '../../../../core/utils/custom_textfield.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/auth_bloc.dart';
import 'auth_page.dart';

class UpdatePasswordPage extends StatelessWidget {
  static const String routeName = '/updatePasswordPage';
  final UpdatePasswordPageArguments arg;
  const UpdatePasswordPage({super.key, required this.arg});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return BlocProvider(
      create: (context) => AuthBloc()..add(GetDirectionEvent()),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) async {
          if (state is AuthInitialState) {
            CustomLoader.loader(context);
          }
          if (state is AuthDataLoadingState) {
            CustomLoader.loader(context);
          }
          if (state is AuthDataLoadedState) {
            CustomLoader.dismiss(context);
          }
          if (state is AuthDataSuccessState) {
            CustomLoader.dismiss(context);
          }
          if (state is ForgotPasswordUpdateSuccessState) {
            final role = await AppSharedPreference.getUserType();
            if (!context.mounted) return;
            Navigator.pushNamedAndRemoveUntil(
                context, AuthPage.routeName, (route) => false,
                arguments: AuthPageArguments(type: role));
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            return GestureDetector(
              onTap: () {
                FocusScope.of(context).requestFocus(FocusNode());
              },
              child: Scaffold(
                body: CustomBackground(
                  child: SafeArea(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: context.read<AuthBloc>().formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                  height:
                                      MediaQuery.sizeOf(context).width * 0.05),
                              Center(
                                child: MyText(
                                  text: AppLocalizations.of(context)!
                                      .forgotPassword,
                                  textAlign: TextAlign.center,
                                  textStyle: Theme.of(context)
                                      .textTheme
                                      .displayMedium!
                                      .copyWith(
                                        color: AppColors.blackText,
                                      ),
                                ),
                              ),
                              SizedBox(height: size.width * 0.1),
                              Center(
                                child: MyText(
                                  text: AppLocalizations.of(context)!
                                      .enterNewPassword,
                                  textAlign: TextAlign.center,
                                  textStyle: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                          color:
                                              Theme.of(context).disabledColor,
                                          fontSize: AppConstants().headerSize),
                                ),
                              ),
                              SizedBox(height: size.width * 0.05),
                              MyText(
                                text: AppLocalizations.of(context)!.password,
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(
                                      color: AppColors.blackText,
                                    ),
                              ),
                              SizedBox(height: size.width * 0.02),
                              buildPasswordField(context, size),
                              SizedBox(height: size.width * 0.02),
                              SizedBox(height: size.width * 0.1),
                              buildButton(context),
                              SizedBox(height: size.width * 0.3),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildButton(BuildContext context) {
    return Center(
      child: CustomButton(
        buttonName: AppLocalizations.of(context)!.change,
        borderRadius: 10,
        height: MediaQuery.sizeOf(context).height * 0.06,
        isLoader: context.read<AuthBloc>().isLoading,
        onTap: () async {
          final role = await AppSharedPreference.getUserType();
          if (!context.mounted) return;
          context.read<AuthBloc>().add(
                UpdatePasswordEvent(
                  isLoginByEmail: arg.isLoginByEmail,
                  password: context.read<AuthBloc>().rPasswordController.text,
                  emailOrMobile: arg.emailOrMobile,
                  role: role,
                ),
              );
        },
      ),
    );
  }

  Widget buildPasswordField(BuildContext context, Size size) {
    return CustomTextField(
      controller: context.read<AuthBloc>().rPasswordController,
      filled: true,
      obscureText: !context.read<AuthBloc>().showPassword,
      hintText: AppLocalizations.of(context)!.enterYourPassword,
      suffixConstraints: BoxConstraints(maxWidth: size.width * 0.2),
      suffixIcon: InkWell(
        onTap: () {
          context.read<AuthBloc>().add(ShowPasswordIconEvent(
              showPassword: context.read<AuthBloc>().showPassword));
        },
        child: !context.read<AuthBloc>().showPassword
            ? const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(
                  Icons.visibility_off_outlined,
                  color: AppColors.darkGrey,
                ),
              )
            : const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(
                  Icons.visibility,
                  color: AppColors.darkGrey,
                ),
              ),
      ),
      validator: (value) {
        if (value!.isEmpty) {
          return AppLocalizations.of(context)!.enterYourPassword;
        } else if (value.length < 8) {
          return AppLocalizations.of(context)!.minimumCharacRequired;
        } else {
          return null;
        }
      },
    );
  }
}
