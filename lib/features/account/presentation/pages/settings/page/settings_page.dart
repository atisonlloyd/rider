import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rides365/features/account/application/acc_bloc.dart';
import 'package:rides365/features/account/presentation/pages/settings/page/faq_page.dart';
import 'package:rides365/features/account/presentation/widgets/top_bar.dart';
import 'package:rides365/features/language/presentation/page/choose_language_page.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../../common/app_constants.dart';
import '../../../../../../common/common.dart';
import '../../../../../../core/model/user_detail_model.dart';
import '../../../../../../core/utils/custom_dialoges.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../../../../auth/presentation/pages/user_choose_page.dart';
import '../../../widgets/page_options.dart';

class SettingsPage extends StatelessWidget {
  static const String routeName = '/settingsPage';
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return BlocProvider(
      create: (context) => AccBloc()..add(AccGetDirectionEvent()),
      child: BlocListener<AccBloc, AccState>(
        listener: (context, state) async {
          if (state is LogoutSuccess) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              SelectUserPage.routeName,
              (route) => false,
            );
            await AppSharedPreference.logoutRemove();
          } else if (state is DeleteAccountSuccess) {
            Navigator.pushNamedAndRemoveUntil(
                context, ChooseLanguagePage.routeName, (route) => false,
                arguments: ChangeLanguageArguments(from: 0));
            await AppSharedPreference.setLoginStatus(false);
            await AppSharedPreference.setToken('');
          } else if (state is DeleteAccountFailureState) {
            Navigator.of(context).pop(); // Dismiss the dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage)),
            );
          }
        },
        child: BlocBuilder<AccBloc, AccState>(builder: (context, state) {
          return Scaffold(
            body: TopBarDesign(
              onTap: () {
                Navigator.pop(context);
              },
              isHistoryPage: false,
              title: AppLocalizations.of(context)!.settings,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: size.height * 0.04),
                    PageOptions(
                      icon: Icons.question_answer,
                      list: AppLocalizations.of(context)!.faq,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          FaqPage.routeName,
                        );
                      },
                    ),
                    PageOptions(
                      icon: Icons.privacy_tip,
                      list: AppLocalizations.of(context)!.privacy,
                      onTap: () async {
                        const browseUrl = AppConstants.privacyPolicy;
                        if (browseUrl.isNotEmpty) {
                          await launchUrl(Uri.parse(browseUrl));
                        } else {
                          throw 'Could not launch $browseUrl';
                        }
                      },
                    ),
                    PageOptions(
                      icon: Icons.logout,
                      list: AppLocalizations.of(context)!.logout,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext _) {
                            return BlocProvider.value(
                              value: BlocProvider.of<AccBloc>(context),
                              child: CustomSingleButtonDialoge(
                                title:
                                    AppLocalizations.of(context)!.comeBackSoon,
                                content:
                                    AppLocalizations.of(context)!.logoutSure,
                                btnName: AppLocalizations.of(context)!.confirm,
                                btnColor: AppColors.errorLight,
                                isLoader: context.read<AccBloc>().isLoading,
                                onTap: () {
                                  context.read<AccBloc>().add(LogoutEvent());
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                    PageOptions(
                      icon: Icons.delete,
                      list: AppLocalizations.of(context)!.deleteAccount,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext _) {
                            return BlocProvider.value(
                              value: BlocProvider.of<AccBloc>(context),
                              child: CustomSingleButtonDialoge(
                                title: userData!.isDeletedAt.isEmpty  ?
                                    '${AppLocalizations.of(context)!.deleteAccount} ?' : AppLocalizations.of(context)!.deleteAccount,
                                content: userData!.isDeletedAt.isEmpty ?
                                    AppLocalizations.of(context)!.deleteText : userData!.isDeletedAt,
                                btnName: userData!.isDeletedAt.isEmpty ?
                                    AppLocalizations.of(context)!.deleteAccount :
                                    AppLocalizations.of(context)!.ok,
                                btnColor: AppColors.errorLight,
                                isLoader: context.read<AccBloc>().isLoading,
                                onTap: () {
                                  if(userData!.isDeletedAt.isEmpty){
                                  context
                                      .read<AccBloc>()
                                      .add(DeleteAccountEvent());
                                  }else{
                                    Navigator.pop(context);
                                  }
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
