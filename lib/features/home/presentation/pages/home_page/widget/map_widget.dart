import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rides365/common/app_constants.dart';
import 'package:rides365/common/common.dart';
import 'package:rides365/core/model/user_detail_model.dart';
import 'package:rides365/core/utils/custom_button.dart';
import 'package:rides365/core/utils/custom_text.dart';
import 'package:rides365/features/home/application/home_bloc.dart';
import 'package:rides365/features/home/presentation/pages/home_page/widget/bidding_ride/bidding_request_widget.dart';
import 'package:rides365/features/home/presentation/pages/home_page/widget/bidding_ride/bidding_ride_list_widget.dart';
import 'package:rides365/features/home/presentation/pages/home_page/widget/on_ride/on_ride_widget.dart';
import 'package:rides365/features/home/presentation/pages/home_page/widget/accept_reject_widget.dart';
import 'package:rides365/features/home/presentation/pages/home_page/widget/outstation_request_page.dart';
import 'package:rides365/features/home/presentation/pages/home_page/widget/instand_ride/avatar_glow.dart';
import 'package:rides365/l10n/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as fmlt;
import '../../../../../../core/utils/shape_painter.dart';
import 'bidding_ride/bidding_timer_widget.dart';
import 'instand_ride/auto_search_places.dart';
import 'earnings_widget.dart';
import 'locate_me_widget.dart';
import 'map_appbar_widget.dart';
import 'on_ride/cancel_reason_widget.dart';
import 'on_ride/navigation_widget.dart';
import 'on_ride/onride_slider_button_widget.dart';
import 'on_ride/signature_get_widget.dart';
import 'outstation_ride_list_widget.dart';
import 'quick_action_widget.dart';
import 'on_ride/sos_widget.dart';
import 'vehicles_status_widget.dart';

class MapWidget extends StatelessWidget {
  final BuildContext cont;

  const MapWidget({super.key, required this.cont});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return BlocProvider.value(
      value: cont.read<HomeBloc>(),
      child: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          context.read<HomeBloc>().bidRideTop ??=
              (size.height) - (size.height * 0.6);
          if (context.read<HomeBloc>().showBiddingPage) {
            if (context.read<HomeBloc>().bidRideTop ==
                (size.height) - (size.height * 0.6)) {
              context.read<HomeBloc>().bidRideTop =
                  MediaQuery.paddingOf(context).top + size.width * 0.05;
            }
          }
          return Stack(
            children: [
              if (context.read<HomeBloc>().currentLatLng != null) ...[
                (mapType == 'google_map')
                    ? BlocProvider<HomeBloc>.value(
                        value: context.read<HomeBloc>(),
                        child:  _MapWidget(context),
                      )
                    : BlocProvider<HomeBloc>.value(
                        value: context.read<HomeBloc>(),
                        child:  _FlutterMapWidget(context),
                      ),
              ],
              if (context.read<HomeBloc>().showGetDropAddress &&
                  context.read<HomeBloc>().polyline.isEmpty) ...[
                BlocProvider<HomeBloc>.value(
                  value: context.read<HomeBloc>(),
                  child: const _DropAddressView(),
                ),
                if (context.read<HomeBloc>().confirmPinAddress)
                  BlocProvider<HomeBloc>.value(
                    value: context.read<HomeBloc>(),
                    child:  _ConfirmPinAddressView(context),
                  ),
              ],
              if (context.read<HomeBloc>().autoSuggestionSearching ||
                  context.read<HomeBloc>().autoCompleteAddress.isNotEmpty)
                BlocProvider<HomeBloc>.value(
                  value: context.read<HomeBloc>(),
                  child: const _AutoSuggestionView(),
                ),
              if (context.read<HomeBloc>().choosenRide != null)
                BlocProvider<HomeBloc>.value(
                  value: context.read<HomeBloc>(),
                  child: const _RideView(),
                ),
              if (userData != null && userData!.role == 'owner') ...[
                ClipPath(
                  clipper: ShapePainter(),
                  child: Container(
                    height: size.width * 0.75,
                    decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        image: const DecorationImage(
                            alignment: Alignment.topCenter,
                            image: AssetImage(AppImages.map))),
                  ),
                ),
                Positioned(
                    top: size.width * 0.3,
                    child: VehicleStatusWidget(cont: context)),
              ],
              if (userData != null &&
                  userData!.role == 'driver' &&
                  userData!.metaRequest == null &&
                  userData!.onTripRequest == null)
                Positioned(top: 0, child: MapAppBarWidget(cont: context)),
              if (context.read<HomeBloc>().autoSuggestionSearching == false &&
                  context.read<HomeBloc>().autoCompleteAddress.isEmpty)
                BlocProvider<HomeBloc>.value(
                  value: context.read<HomeBloc>(),
                  child: const _AutoCompletionEmptyView(),
                ),
              if (userData != null &&
                  userData!.role == 'driver' &&
                  userData!.metaRequest == null &&
                  userData!.onTripRequest == null &&
                  context.read<HomeBloc>().choosenRide == null &&
                  context.read<HomeBloc>().showGetDropAddress == false)
                DraggableScrollableSheet(
                  initialChildSize: 0.25,
                  minChildSize: 0.25,
                  maxChildSize: 1.0,
                  builder: (context, scrollController) {
                    return StatefulBuilder(
                      builder: (context, setState) {
                        return NotificationListener<
                            DraggableScrollableNotification>(
                          onNotification: (notification) {
                            double currentSize = notification.extent;

                            // Determine widget based on height threshold
                            if (currentSize >= 0.6) {
                              context
                                  .read<HomeBloc>()
                                  .animatedWidget =
                                  QuickActionsWidget(cont: cont);
                            } else {
                              context
                                  .read<HomeBloc>()
                                  .animatedWidget = EarningsWidget(cont: cont);
                            }

                            // Update the bottom size in the Bloc
                            context
                                .read<HomeBloc>()
                                .bottomSize = currentSize * size.height;

                            // Trigger a state update
                            context.read<HomeBloc>().add(UpdateEvent());
                            return true;
                          },
                          child: Container(
                            width: size.width,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(size.width * 0.1),
                                topRight: Radius.circular(size.width * 0.1),
                              ),
                              color: Theme
                                  .of(context)
                                  .scaffoldBackgroundColor,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(size.width * 0.1),
                                topRight: Radius.circular(size.width * 0.1),
                              ),
                              child: SingleChildScrollView(
                                controller: scrollController,
                                physics: const ClampingScrollPhysics(),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 400),
                                  child: context
                                      .read<HomeBloc>()
                                      .animatedWidget ??
                                      EarningsWidget(cont: cont),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              if (userData != null &&
                  context.read<HomeBloc>().isBiddingEnabled &&
                  context.read<HomeBloc>().choosenRide == null &&
                  userData!.onTripRequest == null &&
                  userData!.metaRequest == null &&
                  context.read<HomeBloc>().showGetDropAddress == false &&
                  userData!.active &&
                  context.read<HomeBloc>().bottomSize < size.height * 0.6)
                AnimatedPositioned(
                  right: 0,
                  top: context.read<HomeBloc>().bidRideTop,
                  duration: const Duration(milliseconds: 250),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        margin: EdgeInsets.only(right: size.width * 0.05),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: AppColors.white,
                            boxShadow: [
                              BoxShadow(
                                  color: Theme.of(context).shadowColor,
                                  spreadRadius: 1,
                                  blurRadius: 1)
                            ]),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            if (context.read<HomeBloc>().bidRideTop ==
                                (size.height) - (size.height * 0.6)) {
                              context.read<HomeBloc>().bidRideTop =
                                  MediaQuery.paddingOf(context).top +
                                      size.width * 0.05;
                            } else {
                              context.read<HomeBloc>().bidRideTop =
                                  (size.height) - (size.height * 0.6);
                            }
                            context.read<HomeBloc>().add(UpdateEvent());
                            context
                                .read<HomeBloc>()
                                .add(ShowBiddingPageEvent());
                          },
                          child: Container(
                            height: size.width * 0.1,
                            width: size.width * 0.1,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: AppColors.white,
                            ),
                            alignment: Alignment.center,
                            child: Image.asset(
                              AppImages.biddingCar,
                              width: size.width * 0.07,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                      ),
                      AnimatedCrossFade(
                          firstChild: Container(),
                          secondChild: BiddingRideListWidget(cont: context),
                          crossFadeState:
                              (context.read<HomeBloc>().bidRideTop ==
                                      (size.height) - (size.height * 0.6))
                                  ? CrossFadeState.showFirst
                                  : CrossFadeState.showSecond,
                          duration: const Duration(milliseconds: 250))
                    ],
                  ),
                ),
              if (context.read<HomeBloc>().showGetDropAddress)
                Positioned(
                  bottom: 0,
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    height: size.width * 0.5,
                    padding: EdgeInsets.all(size.width * 0.05),
                    width: size.width,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        MyText(
                          text: context.read<HomeBloc>().dropAddress,
                          textStyle: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                          maxLines: 4,
                        ),
                        SizedBox(height: size.width * 0.05),
                        CustomButton(
                            buttonName:
                                AppLocalizations.of(context)!.confirmLocation,
                            onTap: () {
                              context
                                  .read<HomeBloc>()
                                  .add(GetEtaRequestEvent());
                            })
                      ],
                    ),
                  ),
                ),
              if (userData != null && userData!.metaRequest != null)
                Positioned(bottom: 0, child: AcceptRejectWidget(cont: context)),
              if (context.read<HomeBloc>().choosenRide != null &&
                  (context.read<HomeBloc>().outStationList.isNotEmpty ||
                      context.read<HomeBloc>().rideList.isNotEmpty))
                Positioned(
                  bottom: 0,
                  child: Container(
                    width: size.width,
                    padding: EdgeInsets.all(size.width * 0.05),
                    decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        )),
                    child: Column(
                      children: [
                        (context.read<HomeBloc>().choosenRide != null &&
                                context.read<HomeBloc>().showOutstationWidget &&
                                context
                                    .read<HomeBloc>()
                                    .outStationList
                                    .isNotEmpty)
                            ? OutstationRequestWidget(cont: context)
                            : BiddingRequestWidget(cont: context),
                      ],
                    ),
                  ),
                ),
              if (userData != null && (userData!.onTripRequest != null))
                Positioned(
                  bottom: 0,
                  child: SizedBox(
                    height: size.height,
                    width: size.width,
                    child: Stack(
                      children: [
                        DraggableScrollableSheet(
                          initialChildSize:
                              (userData?.onTripRequest!.arrivedAt == null)
                                  ? 0.32
                                  : 0.38, // Start at half screen
                          minChildSize:
                              (userData?.onTripRequest!.arrivedAt == null)
                                  ? 0.32
                                  : 0.38, // Minimum height
                          maxChildSize: 0.80,
                          builder: (BuildContext ctx,
                              ScrollController scrollController) {
                            return Container(
                              height: size.height,
                              width: size.width,
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(30)),
                              ),
                              child: SingleChildScrollView(
                                controller: scrollController,
                                child: (userData != null &&
                                        userData?.onTripRequest != null)
                                    ? ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                                top: Radius.circular(30)),
                                        child: OnRideWidget(cont: context),
                                      )
                                    : Container(),
                              ),
                            );
                          },
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: OnrideCustomSliderButtonWidget(size: size),
                        ),
                      ],
                    ),
                  ),
                ),
              if (context.read<HomeBloc>().visibleOutStation &&
                  userData!.active)
                Positioned(child: BiddingOutStationListWidget(cont: context)),
              // bidding timer widget
              if (context.read<HomeBloc>().waitingList.isNotEmpty &&
                  !context.read<HomeBloc>().showOutstationWidget)
                Positioned(top: 0, child: BiddingTimerWidget(cont: context)),
              // Showing cancel reasons
              if (context.read<HomeBloc>().showCancelReason == true)
                Positioned(top: 0, child: CancelReasonWidget(cont: context)),
              // Showing signature field
              if (context.read<HomeBloc>().showSignature == true)
                Positioned(top: 0, child: SignatureGetWidget(cont: context)),
            ],
          );
        },
      ),
    );
  }
}

class _AutoCompletionEmptyView extends StatelessWidget {
  const _AutoCompletionEmptyView();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Positioned(
        right: (context.read<HomeBloc>().textDirection == 'rtl')
            ? null
            : size.width * 0.05,
        left: (context.read<HomeBloc>().textDirection == 'ltr')
            ? null
            : size.width * 0.05,
        bottom: (userData != null &&
                context.read<HomeBloc>().showGetDropAddress == false &&
                userData!.metaRequest == null &&
                userData!.onTripRequest == null &&
                userData!.role == 'driver')
            ? size.width * 0.75
            : size.height * 0.5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (userData != null &&
                userData!.onTripRequest != null &&
                userData!.onTripRequest!.isTripStart == 1)
              SosWidget(cont: context),
            if (userData != null &&
                userData!.onTripRequest != null &&
                userData!.onTripRequest!.acceptedAt != null &&
                userData!.onTripRequest!.dropAddress != null)
              NavigationWidget(cont: context),
            SizedBox(height: size.width * 0.025),
            LocateMeWidget(cont: context),
          ],
        ));
  }
}

class _RideView extends StatelessWidget {
  const _RideView();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Positioned(
      top: MediaQuery.paddingOf(context).top + size.width * 0.05,
      left: size.width * 0.05,
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                  color: Theme.of(context).shadowColor,
                  spreadRadius: 1,
                  blurRadius: 1)
            ]),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            context.read<HomeBloc>().add(RemoveChoosenRideEvent());
          },
          child: Container(
            height: size.width * 0.1,
            width: size.width * 0.1,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.arrow_back,
              size: size.width * 0.07,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _AutoSuggestionView extends StatelessWidget {
  const _AutoSuggestionView();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      child: AutoSearchPlacesWidget(cont: context),
    );
  }
}

class _ConfirmPinAddressView extends StatelessWidget {
  final BuildContext context;
  const _ConfirmPinAddressView(this.context);

  @override
  Widget build(BuildContext context1) {
    final size = MediaQuery.sizeOf(context1);
    return Positioned(
      // top: (size.height - size.width) / 2,
      top: size.width * 0.23 + MediaQuery.paddingOf(context).top,
      right: size.width * 0.38,
      child: Container(
        height: size.height * 0.8,
        alignment: Alignment.center,
        child: Padding(
            padding: EdgeInsets.only(bottom: size.width * 0.6 + 25),
            child: Row(
              children: [
                CustomButton(
                    height: size.width * 0.08,
                    width: size.width * 0.25,
                    onTap: () {
                      context.read<HomeBloc>().confirmPinAddress = false;
                      context.read<HomeBloc>().add(UpdateEvent());
                      if (context.read<HomeBloc>().mapPoint != null) {
                        context.read<HomeBloc>().add(GeocodingLatLngEvent(
                            lat: context.read<HomeBloc>().mapPoint!.latitude,
                            lng: context.read<HomeBloc>().mapPoint!.longitude));
                      }
                    },
                    textSize: 12,
                    buttonName: AppLocalizations.of(context)!.confirm)
              ],
            )),
      ),
    );
  }
}

class _DropAddressView extends StatelessWidget {
  const _DropAddressView();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Positioned(
        // top: (size.height - size.width * 0.72) / 2,
        top: size.width * 0.53 + MediaQuery.paddingOf(context).top,
        child: SizedBox(
            width: size.width,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AvatarGlow(
                  glowRadiusFactor: 1.0,
                  glowColor: AppColors.primary,
                  child: Container(
                    margin: EdgeInsets.only(bottom: size.width * 0.075),
                    child: Image.asset(
                      AppImages.pickupIcon,
                      height: 20,
                      width: 20,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            )));
  }
}

class _MapWidget extends StatelessWidget {
  final BuildContext context;
  const _MapWidget(this.context);

  @override
  Widget build(BuildContext context1) {
    final size = MediaQuery.sizeOf(context1);

    return GoogleMap(
      key: const PageStorageKey('goole_map'),
      padding: EdgeInsets.fromLTRB(
          size.width * 0.05,
          (context.read<HomeBloc>().choosenRide != null ||
                  context.read<HomeBloc>().showGetDropAddress)
              ? size.width * 0.15 + MediaQuery.paddingOf(context).top
              : size.width * 0.05 + MediaQuery.paddingOf(context).top,
          size.width * 0.05,
          (userData != null &&
                  (userData!.metaRequest != null ||
                      userData!.onTripRequest != null ||
                      context.read<HomeBloc>().choosenRide != null ||
                      context.read<HomeBloc>().showGetDropAddress))
              ? size.width
              : size.width * 0.05),
      gestureRecognizers: {
        Factory<OneSequenceGestureRecognizer>(
          () => EagerGestureRecognizer(),
        ),
      },
      onMapCreated: (GoogleMapController controller) {
        context.read<HomeBloc>().googleMapController = controller;
        context.read<HomeBloc>().add(SetMapStyleEvent(context: context));
      },
      compassEnabled: false,
      initialCameraPosition: CameraPosition(
        target: context.read<HomeBloc>().currentLatLng ?? const LatLng(0, 0),
        zoom: 15.0,
      ),
      onCameraMove: (CameraPosition position) {
        context.read<HomeBloc>().mapPoint = position.target;
      },
      onCameraIdle: () {
        if (context.read<HomeBloc>().showGetDropAddress &&
            context.read<HomeBloc>().mapPoint != null &&
            context.read<HomeBloc>().autoCompleteAddress.isEmpty &&
            context.read<HomeBloc>().polyline.isEmpty) {
          context.read<HomeBloc>().confirmPinAddress = true;
          context.read<HomeBloc>().add(UpdateEvent());
        } else if (context.read<HomeBloc>().showGetDropAddress &&
            context.read<HomeBloc>().mapPoint != null &&
            context.read<HomeBloc>().autoCompleteAddress.isNotEmpty &&
            !context.read<HomeBloc>().confirmPinAddress) {
          context.read<HomeBloc>().add(ClearAutoCompleteEvent());
        }
      },
      markers: Set<Marker>.from(context.read<HomeBloc>().markers),
      minMaxZoomPreference: const MinMaxZoomPreference(0, 20),
      buildingsEnabled: false,
      zoomControlsEnabled: false,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      polylines: context.read<HomeBloc>().polyline,
    );
  }
}

class _FlutterMapWidget extends StatelessWidget {
  final BuildContext context;
  const _FlutterMapWidget(this.context);

  @override
  Widget build(BuildContext context1) {
    return fm.FlutterMap(
      mapController: context.read<HomeBloc>().fmController,
      options: fm.MapOptions(
          onMapEvent: (v) {
            if (v.source == fm.MapEventSource.dragEnd ||
                v.source == fm.MapEventSource.mapController) {
              if (context.read<HomeBloc>().showGetDropAddress &&
                  context.read<HomeBloc>().autoCompleteAddress.isEmpty &&
                  context.read<HomeBloc>().fmpoly.isEmpty) {
                context.read<HomeBloc>().add(GeocodingLatLngEvent(
                    lat: v.camera.center.latitude,
                    lng: v.camera.center.longitude));
              } else if (context.read<HomeBloc>().showGetDropAddress &&
                  context.read<HomeBloc>().mapPoint != null &&
                  context.read<HomeBloc>().autoCompleteAddress.isNotEmpty) {
                context.read<HomeBloc>().add(ClearAutoCompleteEvent());
              }
            }
          },
          initialCenter: fmlt.LatLng(
              context.read<HomeBloc>().currentLatLng!.latitude,
              context.read<HomeBloc>().currentLatLng!.longitude),
          initialZoom: 16,
          onTap: (P, L) {}),
      children: [
        fm.TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.app',
        ),
        if (context.read<HomeBloc>().fmpoly.isNotEmpty)
          fm.PolylineLayer(
            polylines: [
              fm.Polyline(
                  points: context.read<HomeBloc>().fmpoly,
                  color: Theme.of(context).primaryColor,
                  strokeWidth: 4),
            ],
          ),
        if (userData != null && userData!.role == 'owner')
          fm.MarkerLayer(
            markers:
                List.generate(context.read<HomeBloc>().markers.length, (index) {
              final marker = context.read<HomeBloc>().markers.elementAt(index);
              return fm.Marker(
                point: fmlt.LatLng(
                    marker.position.latitude, marker.position.longitude),
                alignment: Alignment.topCenter,
                child: RotationTransition(
                  turns: AlwaysStoppedAnimation(marker.rotation / 360),
                  child: Image.asset(
                    (marker.markerId.value
                                .toString()
                                .replaceAll('MarkerId(', '')
                                .replaceAll(')', '')
                                .split('_')[3] ==
                            'car')
                        ? (marker.markerId.value
                                    .toString()
                                    .replaceAll('MarkerId(', '')
                                    .replaceAll(')', '')
                                    .split('_')[2] ==
                                '1')
                            ? AppImages.carOnline
                            : (marker.markerId.value
                                        .toString()
                                        .replaceAll('MarkerId(', '')
                                        .replaceAll(')', '')
                                        .split('_')[2] ==
                                    '2')
                                ? AppImages.carOffline
                                : AppImages.carOnride
                        : (marker.markerId.value
                                    .toString()
                                    .replaceAll('MarkerId(', '')
                                    .replaceAll(')', '')
                                    .split('_')[3] ==
                                'motor_bike')
                            ? (marker.markerId.value
                                        .toString()
                                        .replaceAll('MarkerId(', '')
                                        .replaceAll(')', '')
                                        .split('_')[2] ==
                                    '1')
                                ? AppImages.bikeOnline
                                : (marker.markerId.value
                                            .toString()
                                            .replaceAll('MarkerId(', '')
                                            .replaceAll(')', '')
                                            .split('_')[2] ==
                                        '2')
                                    ? AppImages.bikeOffline
                                    : AppImages.bikeOnride
                            : (marker.markerId.value
                                        .toString()
                                        .replaceAll('MarkerId(', '')
                                        .replaceAll(')', '')
                                        .split('_')[2] ==
                                    '1')
                                ? AppImages.deliveryOnline
                                : (marker.markerId.value
                                            .toString()
                                            .replaceAll('MarkerId(', '')
                                            .replaceAll(')', '')
                                            .split('_')[2] ==
                                        '2')
                                    ? AppImages.deliveryOffline
                                    : AppImages.deliveryOnride,
                    width: 16,
                    height: 30,
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox();
                    },
                  ),
                ),
              );
            }),
          ),
        if (userData != null && userData!.role != 'owner')
          fm.MarkerLayer(markers: [
            if (context.read<HomeBloc>().currentLatLng != null)
              fm.Marker(
                point: fmlt.LatLng(
                    context.read<HomeBloc>().currentLatLng!.latitude,
                    context.read<HomeBloc>().currentLatLng!.longitude),
                alignment: Alignment.topCenter,
                child: Image.asset(
                  (userData!.vehicleTypeIcon.toString().contains('truck'))
                      ? AppImages.truck
                      : userData!.vehicleTypeIcon
                              .toString()
                              .contains('motor_bike')
                          ? AppImages.bikeOffline
                          : userData!.vehicleTypeIcon
                                  .toString()
                                  .contains('auto')
                              ? AppImages.auto
                              : userData!.vehicleTypeIcon
                                      .toString()
                                      .contains('lcv')
                                  ? AppImages.lcv
                                  : userData!.vehicleTypeIcon
                                          .toString()
                                          .contains('ehcv')
                                      ? AppImages.ehcv
                                      : userData!.vehicleTypeIcon
                                              .toString()
                                              .contains('hatchback')
                                          ? AppImages.hatchBack
                                          : userData!.vehicleTypeIcon
                                                  .toString()
                                                  .contains('hcv')
                                              ? AppImages.hcv
                                              : userData!.vehicleTypeIcon
                                                      .toString()
                                                      .contains('mcv')
                                                  ? AppImages.mcv
                                                  : userData!.vehicleTypeIcon
                                                          .toString()
                                                          .contains('luxury')
                                                      ? AppImages.luxury
                                                      : userData!
                                                              .vehicleTypeIcon
                                                              .toString()
                                                              .contains(
                                                                  'premium')
                                                          ? AppImages.premium
                                                          : userData!
                                                                  .vehicleTypeIcon
                                                                  .toString()
                                                                  .contains(
                                                                      'suv')
                                                              ? AppImages.suv
                                                              : (userData!
                                                                      .vehicleTypeIcon
                                                                      .toString()
                                                                      .contains(
                                                                          'car'))
                                                                  ? AppImages
                                                                      .car
                                                                  : '',
                  width: 16,
                  height: 30,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox();
                  },
                ),
              ),
            if ((userData != null && userData!.metaRequest != null) ||
                (userData != null && userData!.onTripRequest != null))
              (userData != null && userData!.metaRequest != null)
                  ? fm.Marker(
                      width: 100,
                      height: 20,
                      alignment: Alignment.topCenter,
                      point: fmlt.LatLng(userData!.metaRequest!.pickLat,
                          userData!.metaRequest!.pickLng),
                      child: Image.asset(
                        AppImages.pickupIcon,
                        height: 20,
                        width: 20,
                        fit: BoxFit.contain,
                      ),
                    )
                  : fm.Marker(
                      width: 100,
                      height: 30,
                      alignment: Alignment.topCenter,
                      point: fmlt.LatLng(userData!.onTripRequest!.pickLat,
                          userData!.onTripRequest!.pickLng),
                      child: Image.asset(
                        AppImages.pickupIcon,
                        height: 20,
                        width: 20,
                        fit: BoxFit.contain,
                      ),
                    ),
            if ((userData != null &&
                    userData!.metaRequest != null &&
                    userData!.metaRequest!.dropAddress != null &&
                    userData!.metaRequest!.requestStops.isEmpty) ||
                (userData != null &&
                    userData!.onTripRequest != null &&
                    userData!.onTripRequest!.dropAddress != null &&
                    userData!.onTripRequest!.requestStops.isEmpty))
              (userData != null &&
                      userData!.metaRequest != null &&
                      userData!.metaRequest!.dropAddress != null)
                  ? fm.Marker(
                      width: 100,
                      height: 30,
                      alignment: Alignment.topCenter,
                      point: fmlt.LatLng(userData!.metaRequest!.dropLat!,
                          userData!.metaRequest!.dropLng!),
                      child: Image.asset(
                        AppImages.dropIcon,
                        height: 20,
                        width: 20,
                        fit: BoxFit.contain,
                      ),
                    )
                  : fm.Marker(
                      width: 100,
                      height: 30,
                      alignment: Alignment.topCenter,
                      point: fmlt.LatLng(userData!.onTripRequest!.dropLat!,
                          userData!.onTripRequest!.dropLng!),
                      child: Image.asset(
                        AppImages.dropIcon,
                        height: 20,
                        width: 20,
                        fit: BoxFit.contain,
                      ),
                    ),
            if ((userData != null &&
                userData!.metaRequest != null &&
                userData!.metaRequest!.requestStops.isNotEmpty))
              for (var i = 0;
                  i < userData!.metaRequest!.requestStops.length;
                  i++)
                fm.Marker(
                  width: 100,
                  height: 30,
                  alignment: Alignment.center,
                  point: fmlt.LatLng(
                      userData!.metaRequest!.requestStops[i]['latitude'],
                      userData!.metaRequest!.requestStops[i]['longitude']),
                  child: Image.asset(
                    (i == 0)
                        ? AppImages.stopOne
                        : (i == 1)
                            ? AppImages.stopTwo
                            : (i == 2)
                                ? AppImages.stopThree
                                : AppImages.stopFour,
                    height: 15,
                    width: 15,
                    fit: BoxFit.contain,
                  ),
                ),
            if (userData != null &&
                userData!.onTripRequest != null &&
                userData!.onTripRequest!.requestStops.isNotEmpty)
              for (var i = 0;
                  i < userData!.onTripRequest!.requestStops.length;
                  i++)
                fm.Marker(
                  width: 100,
                  height: 30,
                  alignment: Alignment.center,
                  point: fmlt.LatLng(
                      userData!.onTripRequest!.requestStops[i]['latitude'],
                      userData!.onTripRequest!.requestStops[i]['longitude']),
                  child: Image.asset(
                    (i == 0)
                        ? AppImages.stopOne
                        : (i == 1)
                            ? AppImages.stopTwo
                            : (i == 2)
                                ? AppImages.stopThree
                                : AppImages.stopFour,
                    height: 15,
                    width: 15,
                    fit: BoxFit.contain,
                  ),
                ),
          ])
      ],
    );
  }
}

/*
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rides365/common/app_constants.dart';
import 'package:rides365/common/common.dart';
import 'package:rides365/core/model/user_detail_model.dart';
import 'package:rides365/core/utils/custom_button.dart';
import 'package:rides365/core/utils/custom_text.dart';
import 'package:rides365/features/home/application/home_bloc.dart';
import 'package:rides365/features/home/presentation/pages/home_page/widget/bidding_ride/bidding_request_widget.dart';
import 'package:rides365/features/home/presentation/pages/home_page/widget/bidding_ride/bidding_ride_list_widget.dart';
import 'package:rides365/features/home/presentation/pages/home_page/widget/on_ride/on_ride_widget.dart';
import 'package:rides365/features/home/presentation/pages/home_page/widget/accept_reject_widget.dart';
import 'package:rides365/features/home/presentation/pages/home_page/widget/outstation_request_page.dart';
import 'package:rides365/features/home/presentation/pages/home_page/widget/instand_ride/avatar_glow.dart';
import 'package:rides365/l10n/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as fmlt;
import '../../../../../../core/utils/shape_painter.dart';
import 'bidding_ride/bidding_timer_widget.dart';
import 'instand_ride/auto_search_places.dart';
import 'earnings_widget.dart';
import 'locate_me_widget.dart';
import 'map_appbar_widget.dart';
import 'on_ride/cancel_reason_widget.dart';
import 'on_ride/navigation_widget.dart';
import 'on_ride/onride_slider_button_widget.dart';
import 'on_ride/signature_get_widget.dart';
import 'outstation_ride_list_widget.dart';
import 'quick_action_widget.dart';
import 'on_ride/sos_widget.dart';
import 'vehicles_status_widget.dart';

class MapWidget extends StatelessWidget {
  final BuildContext cont;

  const MapWidget({super.key, required this.cont});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return BlocProvider.value(
      value: cont.read<HomeBloc>(),
      child: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          context.read<HomeBloc>().bidRideTop ??=
              (size.height ) - (size.height * 0.6);
          if (context.read<HomeBloc>().showBiddingPage) {
            if (context.read<HomeBloc>().bidRideTop ==
                (size.height) - (size.height * 0.6)) {
              context.read<HomeBloc>().bidRideTop =
                  MediaQuery.of(context).padding.top + size.width * 0.05;
            }
          }
          return Stack(
            children: [
              if (context.read<HomeBloc>().currentLatLng != null) ...[
                (mapType == 'google_map')
                    ? GoogleMap(
                        padding: EdgeInsets.fromLTRB(
                            size.width * 0.05,
                            (context.read<HomeBloc>().choosenRide != null ||
                                    context.read<HomeBloc>().showGetDropAddress)
                                ? size.width * 0.15 +
                                    MediaQuery.of(context).padding.top
                                : size.width * 0.05 +
                                    MediaQuery.of(context).padding.top,
                            size.width * 0.05,
                            (userData != null &&
                                    (userData!.metaRequest != null ||
                                        userData!.onTripRequest != null ||
                                        context.read<HomeBloc>().choosenRide !=
                                            null ||
                                        context
                                            .read<HomeBloc>()
                                            .showGetDropAddress))
                                ? size.width
                                : size.width * 0.05),
                        gestureRecognizers: {
                          Factory<OneSequenceGestureRecognizer>(
                            () => EagerGestureRecognizer(),
                          ),
                        },
                        onMapCreated: (GoogleMapController controller) {
                          context.read<HomeBloc>().googleMapController =
                              controller;
                          context
                              .read<HomeBloc>()
                              .add(SetMapStyleEvent(context: context));
                        },
                        compassEnabled: false,
                        initialCameraPosition: CameraPosition(
                          target: context.read<HomeBloc>().currentLatLng ??
                              const LatLng(0, 0),
                          zoom: 15.0,
                        ),
                        onCameraMove: (CameraPosition position) {
                          context.read<HomeBloc>().mapPoint = position.target;
                        },
                        onCameraIdle: () {
                          if (context.read<HomeBloc>().showGetDropAddress &&
                              context.read<HomeBloc>().mapPoint != null &&
                              context
                                  .read<HomeBloc>()
                                  .autoCompleteAddress
                                  .isEmpty &&
                              context.read<HomeBloc>().polyline.isEmpty) {
                            context.read<HomeBloc>().confirmPinAddress = true;
                            context.read<HomeBloc>().add(UpdateEvent());
                          } else if (context
                                  .read<HomeBloc>()
                                  .showGetDropAddress &&
                              context.read<HomeBloc>().mapPoint != null &&
                              context
                                  .read<HomeBloc>()
                                  .autoCompleteAddress
                                  .isNotEmpty &&
                              !context.read<HomeBloc>().confirmPinAddress) {
                            context
                                .read<HomeBloc>()
                                .add(ClearAutoCompleteEvent());
                          }
                        },
                        markers:
                            Set<Marker>.from(context.read<HomeBloc>().markers),
                        minMaxZoomPreference: const MinMaxZoomPreference(0, 20),
                        buildingsEnabled: false,
                        zoomControlsEnabled: false,
                        myLocationEnabled: false,
                        myLocationButtonEnabled: false,
                        polylines: context.read<HomeBloc>().polyline,
                      )
                    : fm.FlutterMap(
                        mapController: context.read<HomeBloc>().fmController,
                        options: fm.MapOptions(
                            onMapEvent: (v) {
                              if (v.source == fm.MapEventSource.dragEnd ||
                                  v.source == fm.MapEventSource.mapController) {
                                if (context
                                        .read<HomeBloc>()
                                        .showGetDropAddress &&
                                    context
                                        .read<HomeBloc>()
                                        .autoCompleteAddress
                                        .isEmpty &&
                                    context.read<HomeBloc>().fmpoly.isEmpty) {
                                  context.read<HomeBloc>().add(
                                      GeocodingLatLngEvent(
                                          lat: v.camera.center.latitude,
                                          lng: v.camera.center.longitude));
                                } else if (context
                                        .read<HomeBloc>()
                                        .showGetDropAddress &&
                                    context.read<HomeBloc>().mapPoint != null &&
                                    context
                                        .read<HomeBloc>()
                                        .autoCompleteAddress
                                        .isNotEmpty) {
                                  context
                                      .read<HomeBloc>()
                                      .add(ClearAutoCompleteEvent());
                                }
                              }
                            },
                            initialCenter: fmlt.LatLng(
                                context
                                    .read<HomeBloc>()
                                    .currentLatLng!
                                    .latitude,
                                context
                                    .read<HomeBloc>()
                                    .currentLatLng!
                                    .longitude),
                            initialZoom: 16,
                            onTap: (P, L) {}),
                        children: [
                          fm.TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.app',
                          ),
                          if (context.read<HomeBloc>().fmpoly.isNotEmpty)
                            fm.PolylineLayer(
                              polylines: [
                                fm.Polyline(
                                    points: context.read<HomeBloc>().fmpoly,
                                    color: Theme.of(context).primaryColor,
                                    strokeWidth: 4),
                              ],
                            ),
                          if (userData != null && userData!.role == 'owner')
                            fm.MarkerLayer(
                              markers: List.generate(
                                  context.read<HomeBloc>().markers.length,
                                  (index) {
                                final marker = context
                                    .read<HomeBloc>()
                                    .markers
                                    .elementAt(index);
                                return fm.Marker(
                                  point: fmlt.LatLng(marker.position.latitude,
                                      marker.position.longitude),
                                  alignment: Alignment.topCenter,
                                  child: RotationTransition(
                                    turns: AlwaysStoppedAnimation(
                                        marker.rotation / 360),
                                    child: Image.asset(
                                      (marker.markerId.value
                                                  .toString()
                                                  .replaceAll('MarkerId(', '')
                                                  .replaceAll(')', '')
                                                  .split('_')[3] ==
                                              'car')
                                          ? (marker.markerId.value
                                                      .toString()
                                                      .replaceAll(
                                                          'MarkerId(', '')
                                                      .replaceAll(')', '')
                                                      .split('_')[2] ==
                                                  '1')
                                              ? AppImages.carOnline
                                              : (marker.markerId.value
                                                          .toString()
                                                          .replaceAll(
                                                              'MarkerId(', '')
                                                          .replaceAll(')', '')
                                                          .split('_')[2] ==
                                                      '2')
                                                  ? AppImages.carOffline
                                                  : AppImages.carOnride
                                          : (marker.markerId.value
                                                      .toString()
                                                      .replaceAll(
                                                          'MarkerId(', '')
                                                      .replaceAll(')', '')
                                                      .split('_')[3] ==
                                                  'motor_bike')
                                              ? (marker.markerId.value
                                                          .toString()
                                                          .replaceAll(
                                                              'MarkerId(', '')
                                                          .replaceAll(')', '')
                                                          .split('_')[2] ==
                                                      '1')
                                                  ? AppImages.bikeOnline
                                                  : (marker.markerId.value
                                                              .toString()
                                                              .replaceAll('MarkerId(', '')
                                                              .replaceAll(')', '')
                                                              .split('_')[2] ==
                                                          '2')
                                                      ? AppImages.bikeOffline
                                                      : AppImages.bikeOnride
                                              : (marker.markerId.value.toString().replaceAll('MarkerId(', '').replaceAll(')', '').split('_')[2] == '1')
                                                  ? AppImages.deliveryOnline
                                                  : (marker.markerId.value.toString().replaceAll('MarkerId(', '').replaceAll(')', '').split('_')[2] == '2')
                                                      ? AppImages.deliveryOffline
                                                      : AppImages.deliveryOnride,
                                      width: 16,
                                      height: 30,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const SizedBox();
                                      },
                                    ),
                                  ),
                                );
                              }),
                            ),
                          if (userData != null && userData!.role != 'owner')
                            fm.MarkerLayer(markers: [
                              if (context.read<HomeBloc>().currentLatLng !=
                                  null)
                                fm.Marker(
                                  point: fmlt.LatLng(
                                      context
                                          .read<HomeBloc>()
                                          .currentLatLng!
                                          .latitude,
                                      context
                                          .read<HomeBloc>()
                                          .currentLatLng!
                                          .longitude),
                                  alignment: Alignment.topCenter,
                                  child: Image.asset(
                                    (userData!.vehicleTypeIcon
                                            .toString()
                                            .contains('truck'))
                                        ? AppImages.truck
                                        : userData!.vehicleTypeIcon
                                                .toString()
                                                .contains('motor_bike')
                                            ? AppImages.bikeOffline
                                            : userData!.vehicleTypeIcon
                                                    .toString()
                                                    .contains('auto')
                                                ? AppImages.auto
                                                : userData!.vehicleTypeIcon
                                                        .toString()
                                                        .contains('lcv')
                                                    ? AppImages.lcv
                                                    : userData!.vehicleTypeIcon
                                                            .toString()
                                                            .contains('ehcv')
                                                        ? AppImages.ehcv
                                                        : userData!
                                                                .vehicleTypeIcon
                                                                .toString()
                                                                .contains(
                                                                    'hatchback')
                                                            ? AppImages
                                                                .hatchBack
                                                            : userData!
                                                                    .vehicleTypeIcon
                                                                    .toString()
                                                                    .contains(
                                                                        'hcv')
                                                                ? AppImages.hcv
                                                                : userData!
                                                                        .vehicleTypeIcon
                                                                        .toString()
                                                                        .contains(
                                                                            'mcv')
                                                                    ? AppImages
                                                                        .mcv
                                                                    : userData!
                                                                            .vehicleTypeIcon
                                                                            .toString()
                                                                            .contains(
                                                                                'luxury')
                                                                        ? AppImages
                                                                            .luxury
                                                                        : userData!.vehicleTypeIcon.toString().contains('premium')
                                                                            ? AppImages.premium
                                                                            : userData!.vehicleTypeIcon.toString().contains('suv')
                                                                                ? AppImages.suv
                                                                                : (userData!.vehicleTypeIcon.toString().contains('car'))
                                                                                    ? AppImages.car
                                                                                    : '',
                                    width: 16,
                                    height: 30,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const SizedBox();
                                    },
                                  ),
                                ),
                              if ((userData != null &&
                                      userData!.metaRequest != null) ||
                                  (userData != null &&
                                      userData!.onTripRequest != null))
                                (userData != null &&
                                        userData!.metaRequest != null)
                                    ? fm.Marker(
                                        width: 100,
                                        height: 20,
                                        alignment: Alignment.topCenter,
                                        point: fmlt.LatLng(
                                            userData!.metaRequest!.pickLat,
                                            userData!.metaRequest!.pickLng),
                                        child: Image.asset(
                                          AppImages.pickupIcon,
                                          height: 20,
                                          width: 20,
                                          fit: BoxFit.contain,
                                        ),
                                      )
                                    : fm.Marker(
                                        width: 100,
                                        height: 30,
                                        alignment: Alignment.topCenter,
                                        point: fmlt.LatLng(
                                            userData!.onTripRequest!.pickLat,
                                            userData!.onTripRequest!.pickLng),
                                        child: Image.asset(
                                          AppImages.pickupIcon,
                                          height: 20,
                                          width: 20,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                              if ((userData != null &&
                                      userData!.metaRequest != null &&
                                      userData!.metaRequest!.dropAddress !=
                                          null &&
                                      userData!
                                          .metaRequest!.requestStops.isEmpty) ||
                                  (userData != null &&
                                      userData!.onTripRequest != null &&
                                      userData!.onTripRequest!.dropAddress !=
                                          null &&
                                      userData!
                                          .onTripRequest!.requestStops.isEmpty))
                                (userData != null &&
                                        userData!.metaRequest != null &&
                                        userData!.metaRequest!.dropAddress !=
                                            null)
                                    ? fm.Marker(
                                        width: 100,
                                        height: 30,
                                        alignment: Alignment.topCenter,
                                        point: fmlt.LatLng(
                                            userData!.metaRequest!.dropLat!,
                                            userData!.metaRequest!.dropLng!),
                                        child: Image.asset(
                                          AppImages.dropIcon,
                                          height: 20,
                                          width: 20,
                                          fit: BoxFit.contain,
                                        ),
                                      )
                                    : fm.Marker(
                                        width: 100,
                                        height: 30,
                                        alignment: Alignment.topCenter,
                                        point: fmlt.LatLng(
                                            userData!.onTripRequest!.dropLat!,
                                            userData!.onTripRequest!.dropLng!),
                                        child: Image.asset(
                                          AppImages.dropIcon,
                                          height: 20,
                                          width: 20,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                              if ((userData != null &&
                                  userData!.metaRequest != null &&
                                  userData!
                                      .metaRequest!.requestStops.isNotEmpty))
                                for (var i = 0;
                                    i <
                                        userData!
                                            .metaRequest!.requestStops.length;
                                    i++)
                                  fm.Marker(
                                    width: 100,
                                    height: 30,
                                    alignment: Alignment.center,
                                    point: fmlt.LatLng(
                                        userData!.metaRequest!.requestStops[i]
                                            ['latitude'],
                                        userData!.metaRequest!.requestStops[i]
                                            ['longitude']),
                                    child: Image.asset(
                                      (i == 0)
                                          ? AppImages.stopOne
                                          : (i == 1)
                                              ? AppImages.stopTwo
                                              : (i == 2)
                                                  ? AppImages.stopThree
                                                  : AppImages.stopFour,
                                      height: 15,
                                      width: 15,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                              if (userData != null &&
                                  userData!.onTripRequest != null &&
                                  userData!
                                      .onTripRequest!.requestStops.isNotEmpty)
                                for (var i = 0;
                                    i <
                                        userData!
                                            .onTripRequest!.requestStops.length;
                                    i++)
                                  fm.Marker(
                                    width: 100,
                                    height: 30,
                                    alignment: Alignment.center,
                                    point: fmlt.LatLng(
                                        userData!.onTripRequest!.requestStops[i]
                                            ['latitude'],
                                        userData!.onTripRequest!.requestStops[i]
                                            ['longitude']),
                                    child: Image.asset(
                                      (i == 0)
                                          ? AppImages.stopOne
                                          : (i == 1)
                                              ? AppImages.stopTwo
                                              : (i == 2)
                                                  ? AppImages.stopThree
                                                  : AppImages.stopFour,
                                      height: 15,
                                      width: 15,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                            ])
                        ],
                      ),
              ],
              if (context.read<HomeBloc>().showGetDropAddress &&
                  context.read<HomeBloc>().polyline.isEmpty) ...[
                Positioned(
                    // top: (size.height - size.width * 0.72) / 2,
                    top: size.width * 0.53 + MediaQuery.of(context).padding.top,
                    child: SizedBox(
                        width: size.width,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AvatarGlow(
                              glowRadiusFactor: 1.0,
                              glowColor: AppColors.primary,
                              child: Container(
                                margin:
                                    EdgeInsets.only(bottom: size.width * 0.075),
                                child: Image.asset(
                                  AppImages.pickupIcon,
                                  height: 20,
                                  width: 20,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ],
                        ))),
                if (context.read<HomeBloc>().confirmPinAddress)
                  // Positioned(
                  //   top: size.width * 0.4,
                  //   child: Container(
                  //     height: size.height * 0.8,
                  //     width: size.width,
                  //     alignment: Alignment.center,
                  //     child: Row(
                  //       mainAxisAlignment: MainAxisAlignment.center,
                  //       children: [
                  //         Container(
                  //           padding: EdgeInsets.only(
                  //               bottom: size.width * 0.6 + size.width * 0.06),
                  //           child: Container(
                  //               padding: EdgeInsets.only(
                  //                   left: size.width * 0.02,
                  //                   right: size.width * 0.02,
                  //                   top: size.width * 0.01,
                  //                   bottom: size.width * 0.01),
                  //               decoration: BoxDecoration(
                  //                 color: AppColors.white,
                  //                 borderRadius:
                  //                     BorderRadius.circular(size.width * 0.02),
                  //               ),
                  //               child: MyText(
                  //                   text:
                  //                       'Drag To Get Address Feature Not Available In demo',
                  //                   textStyle: Theme.of(context)
                  //                       .textTheme
                  //                       .labelLarge!
                  //                       .copyWith(color: AppColors.black))),
                  //         )
                  //       ],
                  //     ),
                  //   ),
                  // ),
                  Positioned(
                    // top: (size.height - size.width) / 2,
                    top: size.width * 0.23 + MediaQuery.of(context).padding.top,
                    right: size.width * 0.38,
                    child: Container(
                      height: size.height * 0.8,
                      alignment: Alignment.center,
                      child: Padding(
                          padding:
                              EdgeInsets.only(bottom: size.width * 0.6 + 25),
                          child: Row(
                            children: [
                              CustomButton(
                                  height: size.width * 0.08,
                                  width: size.width * 0.25,
                                  onTap: () {
                                    context.read<HomeBloc>().confirmPinAddress =
                                        false;
                                    context.read<HomeBloc>().add(UpdateEvent());
                                    if (context.read<HomeBloc>().mapPoint !=
                                        null) {
                                      context.read<HomeBloc>().add(
                                          GeocodingLatLngEvent(
                                              lat: context
                                                  .read<HomeBloc>()
                                                  .mapPoint!
                                                  .latitude,
                                              lng: context
                                                  .read<HomeBloc>()
                                                  .mapPoint!
                                                  .longitude));
                                    }
                                  },
                                  textSize: 12,
                                  buttonName:
                                      AppLocalizations.of(context)!.confirm)
                            ],
                          )),
                    ),
                  ),
              ],
              if (context.read<HomeBloc>().autoSuggestionSearching ||
                  context.read<HomeBloc>().autoCompleteAddress.isNotEmpty)
                Positioned(
                  top: 0,
                  child: AutoSearchPlacesWidget(cont: context),
                ),
              if (context.read<HomeBloc>().choosenRide != null)
                Positioned(
                  top: MediaQuery.of(context).padding.top + size.width * 0.05,
                  left: size.width * 0.05,
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: AppColors.white,
                        boxShadow: [
                          BoxShadow(
                              color: Theme.of(context).shadowColor,
                              spreadRadius: 1,
                              blurRadius: 1)
                        ]),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        context.read<HomeBloc>().add(RemoveChoosenRideEvent());
                      },
                      child: Container(
                        height: size.width * 0.1,
                        width: size.width * 0.1,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          size: size.width * 0.07,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              if (userData != null && userData!.role == 'owner') ...[
                ClipPath(
                  clipper: ShapePainter(),
                  child: Container(
                    height: size.width * 0.75,
                    decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        image: const DecorationImage(
                            alignment: Alignment.topCenter,
                            image: AssetImage(AppImages.map))),
                  ),
                ),
                Positioned(
                    top: size.width * 0.3,
                    child: VehicleStatusWidget(cont: context)),
              ],
              if (userData != null &&
                  userData!.role == 'driver' &&


                  userData!.metaRequest == null &&
                  userData!.onTripRequest == null)
                Positioned(top: 0, child: MapAppBarWidget(cont: context)),
              if (context.read<HomeBloc>().autoSuggestionSearching == false &&
                  context.read<HomeBloc>().autoCompleteAddress.isEmpty)
                Positioned(
                    right: (context.read<HomeBloc>().textDirection == 'rtl')
                        ? null
                        : size.width * 0.05,
                    left: (context.read<HomeBloc>().textDirection == 'ltr')
                        ? null
                        : size.width * 0.05,
                    bottom: (userData != null &&
                            context.read<HomeBloc>().showGetDropAddress ==
                                false &&
                            userData!.metaRequest == null &&
                            userData!.onTripRequest == null &&
                            userData!.role == 'driver')
                        ? size.width * 0.75
                        : size.height * 0.5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (userData != null &&
                            userData!.onTripRequest != null &&
                            userData!.onTripRequest!.isTripStart == 1)
                          SosWidget(cont: context),
                        if (userData != null &&
                            userData!.onTripRequest != null &&
                            userData!.onTripRequest!.acceptedAt != null &&
                            userData!.onTripRequest!.dropAddress != null)
                          NavigationWidget(cont: context),
                        SizedBox(height: size.width * 0.025),
                        LocateMeWidget(cont: context),
                      ],
                    )),
              if (userData != null &&
                  userData!.role == 'driver' &&
                  userData!.metaRequest == null &&
                  userData!.onTripRequest == null &&
                  context.read<HomeBloc>().choosenRide == null &&
                  context.read<HomeBloc>().showGetDropAddress == false)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  bottom: context.read<HomeBloc>().bottomSize,
                  child: GestureDetector(
                    onVerticalDragStart: (details) {
                      context.read<HomeBloc>().onRideBottomCurrentHeight =
                          details.globalPosition.dy;
                    },
                    onVerticalDragUpdate: (details) {
                      double deltaY = details.globalPosition.dy -
                          context.read<HomeBloc>().onRideBottomCurrentHeight;
                      double newPosition =
                          context.read<HomeBloc>().bottomSize - deltaY;

                      // Set bounds for the new position
                      if (newPosition > 0) {
                        newPosition = 0; // Prevent going above screen
                      }
                      if (newPosition > size.height * 0.6) {
                        newPosition = size.height * 0.3; // Max height
                      }

                      context.read<HomeBloc>().bottomSize = newPosition;

                      context.read<HomeBloc>().onRideBottomCurrentHeight =
                          details.globalPosition
                              .dy; // Update the drag start position
                      context.read<HomeBloc>().add(UpdateEvent());
                    },
                    onVerticalDragEnd: (v) {
                      double finalHeight = context.read<HomeBloc>().bottomSize;

                      // If the height is less than the minHeight, snap it back to the minHeight
                      if (finalHeight < context.read<HomeBloc>().minHeight) {
                        finalHeight = context.read<HomeBloc>().minHeight;
                        context.read<HomeBloc>().animatedWidget =
                            EarningsWidget(cont: cont);
                      } else {
                        finalHeight = 0.0;
                        context.read<HomeBloc>().animatedWidget =
                            QuickActionsWidget(cont: cont);
                      }
                      context.read<HomeBloc>().add(
                          UpdateBottomHeightEvent(bottomHeight: finalHeight));

                      context.read<HomeBloc>().add(UpdateEvent());
                    },
                    child: Container(
                      width: size.width,
                      height: size.height,
                      padding: EdgeInsets.all(
                          context.read<HomeBloc>().bottomSize <=
                                  context.read<HomeBloc>().minHeight
                              ? size.width * 0.05
                              : 0),
                      decoration: BoxDecoration(
                        borderRadius: context.read<HomeBloc>().bottomSize <=
                                context.read<HomeBloc>().minHeight
                            ? BorderRadius.only(
                                topLeft: Radius.circular(size.width * 0.1),
                                topRight: Radius.circular(size.width * 0.1))
                            : BorderRadius.circular(0),
                        color: Theme.of(context).scaffoldBackgroundColor,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: context.read<HomeBloc>().animatedWidget ??
                            EarningsWidget(cont: cont),
                      ),
                    ),
                  ),
                ),
              if (userData != null &&
                  context.read<HomeBloc>().isBiddingEnabled &&
                  context.read<HomeBloc>().choosenRide == null &&
                  userData!.onTripRequest == null &&
                  userData!.metaRequest == null &&
                  context.read<HomeBloc>().showGetDropAddress == false &&
                  userData!.active &&
                  context.read<HomeBloc>().bottomSize <=
                      context.read<HomeBloc>().minHeight)
                AnimatedPositioned(
                  right: 0,
                  top: context.read<HomeBloc>().bidRideTop,
                  duration: const Duration(milliseconds: 250),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        margin: EdgeInsets.only(right: size.width * 0.05),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: AppColors.white,
                            boxShadow: [
                              BoxShadow(
                                  color: Theme.of(context).shadowColor,
                                  spreadRadius: 1,
                                  blurRadius: 1)
                            ]),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            if (context.read<HomeBloc>().bidRideTop ==
                                (size.height) -
                                    (size.height * 0.6)) {
                              context.read<HomeBloc>().bidRideTop =
                                  MediaQuery.of(context).padding.top +
                                      size.width * 0.05;
                            } else {
                              context.read<HomeBloc>().bidRideTop =
                                  (size.height) -
                                      (size.height * 0.6);
                            }
                            context.read<HomeBloc>().add(UpdateEvent());
                            context
                                .read<HomeBloc>()
                                .add(ShowBiddingPageEvent());
                          },
                          child: Container(
                            height: size.width * 0.1,
                            width: size.width * 0.1,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: AppColors.white,
                            ),
                            alignment: Alignment.center,
                            child: Image.asset(
                              AppImages.biddingCar,
                              width: size.width * 0.07,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                      ),
                      AnimatedCrossFade(
                          firstChild: Container(),
                          secondChild: BiddingRideListWidget(cont: context),
                          crossFadeState:
                              (context.read<HomeBloc>().bidRideTop ==
                                      (size.height ) -
                                          (size.height * 0.6))
                                  ? CrossFadeState.showFirst
                                  : CrossFadeState.showSecond,
                          duration: const Duration(milliseconds: 250))
                    ],
                  ),
                ),
              if (context.read<HomeBloc>().showGetDropAddress)
                Positioned(
                  bottom: 0,
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    height: size.width * 0.5,
                    padding: EdgeInsets.all(size.width * 0.05),
                    width: size.width,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        MyText(
                          text: context.read<HomeBloc>().dropAddress,
                          textStyle: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                          maxLines: 4,
                        ),
                        SizedBox(height: size.width * 0.05),
                        CustomButton(
                            buttonName:
                                AppLocalizations.of(context)!.confirmLocation,
                            onTap: () {
                              context
                                  .read<HomeBloc>()
                                  .add(GetEtaRequestEvent());
                            })
                      ],
                    ),
                  ),
                ),
              if (userData != null && userData!.metaRequest != null)
                Positioned(bottom: 0, child: AcceptRejectWidget(cont: context)),
              if (context.read<HomeBloc>().choosenRide != null &&
                  (context.read<HomeBloc>().outStationList.isNotEmpty ||
                      context.read<HomeBloc>().rideList.isNotEmpty))
                Positioned(
                  bottom: 0,
                  child: Container(
                    width: size.width,
                    padding: EdgeInsets.all(size.width * 0.05),
                    decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        )),
                    child: Column(
                      children: [
                        (context.read<HomeBloc>().choosenRide != null &&
                                context.read<HomeBloc>().showOutstationWidget &&
                                context
                                    .read<HomeBloc>()
                                    .outStationList
                                    .isNotEmpty)
                            ? OutstationRequestWidget(cont: context)
                            : BiddingRequestWidget(cont: context),
                      ],
                    ),
                  ),
                ),
              if (userData != null && (userData!.onTripRequest != null))
                Positioned(
                  bottom: 0,
                  child: SizedBox(
                    height: size.height,
                    width: size.width,
                    child: Stack(
                      children: [
                        DraggableScrollableSheet(
                          initialChildSize:
                              (userData?.onTripRequest!.arrivedAt == null)
                                  ? 0.32
                                  : 0.38, // Start at half screen
                          minChildSize:
                              (userData?.onTripRequest!.arrivedAt == null)
                                  ? 0.32
                                  : 0.38, // Minimum height
                          maxChildSize: 0.80,
                          builder: (BuildContext ctx,
                              ScrollController scrollController) {
                            return Container(
                              height: size.height,
                              width: size.width,
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                                borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(30)),
                              ),
                              child: SingleChildScrollView(
                                controller: scrollController,
                                child: (userData != null &&
                                        userData?.onTripRequest != null)
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(30)),
                                        child: OnRideWidget(cont: context),
                                      )
                                    : Container(),
                              ),
                            );
                          },
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: OnrideCustomSliderButtonWidget(size: size),
                        ),
                      ],
                    ),
                  ),
                ),
              if (context.read<HomeBloc>().visibleOutStation &&
                  userData!.active)
                Positioned(child: BiddingOutStationListWidget(cont: context)),
              // bidding timer widget
              if (context.read<HomeBloc>().waitingList.isNotEmpty &&
                  !context.read<HomeBloc>().showOutstationWidget)
                Positioned(top: 0, child: BiddingTimerWidget(cont: context)),
               // Showing cancel reasons  
              if (context.read<HomeBloc>().showCancelReason == true)
                Positioned(top: 0, child: CancelReasonWidget(cont: context)),
              // Showing signature field
              if (context.read<HomeBloc>().showSignature == true)
                Positioned(top: 0, child: SignatureGetWidget(cont: context)),
            ],
          );
        },
      ),
    );
  }
}
*/
