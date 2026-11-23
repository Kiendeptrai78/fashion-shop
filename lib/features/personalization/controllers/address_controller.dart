import 'package:latlong2/latlong.dart';
import 'package:fashion_business_app/features/personalization/screens/address/widgets/address_selection_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fashion_business_app/common/widgets/loaders/loader.dart';
import 'package:fashion_business_app/data/repositories/adddresses/address_repository.dart';
import 'package:fashion_business_app/features/authentication/controllers/signup/network_manager.dart';
import 'package:fashion_business_app/features/personalization/models/address_model.dart';
import 'package:fashion_business_app/utils/constants/colors.dart';
import 'package:fashion_business_app/utils/constants/image_strings.dart';
import 'package:fashion_business_app/utils/popups/full_screen_loader.dart';

class AddressController extends GetxController{
  static AddressController get instance => Get.find();

  final location = Rxn<LatLng>();
  final name = TextEditingController();
  final phoneNumber = TextEditingController();
  final street = TextEditingController();
  final city = TextEditingController();
  final state = TextEditingController();
  final country = TextEditingController();
  GlobalKey<FormState> addressFormKey = GlobalKey<FormState>();

  RxBool refreshData = true.obs;
  final Rx<AddressModel> selectedAddress = AddressModel.empty().obs;
  final addressRepository = Get.put(AddressRepository());

  ///fetch all user specific addresses
  Future<List<AddressModel>> getAllUserAddresses() async{
    try{
      final addresses = await addressRepository.fetchUserAddresses();
      selectedAddress.value = addresses.firstWhere((element) => element.selectedAddress, orElse: () => AddressModel.empty());
      return addresses;
    }catch(e){
      rethrow;
    }
  }

  ///
  Future<bool> selectAddress(AddressModel newSelectedAddress) async{
    try{
      Get.defaultDialog(
        title: '',
        onWillPop: () async {return false;},
        barrierDismissible: false,
        backgroundColor: Colors.transparent,
        content: const CircularProgressIndicator(color: TColors.primaryColor,),
      );

      await addressRepository.selectAddress(newSelectedAddress.id);
      newSelectedAddress.selectedAddress = true;
      selectedAddress.value = newSelectedAddress;
      Get.back();
      return true;
    }catch(e){
      if (Get.isDialogOpen == true) Get.back();
      TLoaders.errorSnackBar(title: 'Error in Selection!',message: e.toString());
      return false;
    }
  }

  ///
  Future addNewAddresses() async{
    try{
    //start loading
      TFullScreenLoader.openLoadingDialog('Storing Address...', TImages.loading);

      //check internet connectivity
      final isConnected = await NetworkManager.instance.isConnected();
      if(!isConnected){
        TFullScreenLoader.stopLoading();
        return;
      }

      //form validation
      if(!addressFormKey.currentState!.validate()){
        TFullScreenLoader.stopLoading();
        return;
      }

      //save address data
      final address = AddressModel(
          id: '',
          name: name.text.trim(),
          phoneNumber: phoneNumber.text.trim(),
          street: street.text.trim(),
          city: city.text.trim(),
          state: state.text.trim(),
          country: country.text.trim().isNotEmpty ? country.text.trim() : 'Việt Nam',
          selectedAddress: true,
          latitude: location.value?.latitude, longitude: location.value?.longitude,
      );
      final id = await addressRepository.addAddress(address);

      //update selected address status
      address.id = id;
      await selectAddress(address);

      //remove loader
      TFullScreenLoader.stopLoading();

      //show success
      TLoaders.successSnackBar(title: 'Congratulations', message: 'Your address has been saved successfully');

      //refresh addresses
      refreshData.toggle();

      //reset field
      resetFormFields();

      //redirect
      Get.back(result: address);
    }catch(e){
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: 'Address not found!',message: e.toString());
    }
  }

  /// Update an existing saved address
  Future<void> updateAddress(AddressModel existing) async {
    try {
      TFullScreenLoader.openLoadingDialog('Đang cập nhật địa chỉ...', TImages.loading);

      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        return;
      }

      if (!addressFormKey.currentState!.validate()) {
        TFullScreenLoader.stopLoading();
        return;
      }

      final updated = AddressModel(
        id: existing.id,
        name: name.text.trim(),
        phoneNumber: phoneNumber.text.trim(),
        street: street.text.trim(),
        city: city.text.trim(),
        state: state.text.trim(),
        country: country.text.trim().isNotEmpty ? country.text.trim() : 'Việt Nam',
        selectedAddress: existing.selectedAddress,
        latitude: location.value?.latitude,
        longitude: location.value?.longitude,
      );

      await addressRepository.updateAddress(updated);

      if (selectedAddress.value.id == existing.id) {
        selectedAddress.value = updated;
      }

      TFullScreenLoader.stopLoading();
      TLoaders.successSnackBar(
        title: 'Thành công',
        message: 'Đã cập nhật địa chỉ giao hàng của bạn',
      );
      refreshData.toggle();
      resetFormFields();
      Get.back(result: updated);
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(
        title: 'Không thể cập nhật địa chỉ',
        message: e.toString(),
      );
    }
  }

  /// Delete a saved address
  Future<void> deleteAddress(AddressModel address) async {
    try {
      await addressRepository.deleteAddress(address.id);
      if (selectedAddress.value.id == address.id) {
        final remaining = await addressRepository.fetchUserAddresses();
        if (remaining.isNotEmpty) {
          await addressRepository.selectAddress(remaining.first.id);
          remaining.first.selectedAddress = true;
          selectedAddress.value = remaining.first;
        } else {
          selectedAddress.value = AddressModel.empty();
        }
      }
      refreshData.toggle();
      TLoaders.successSnackBar(
        title: 'Đã xóa địa chỉ',
        message: 'Địa chỉ nhận hàng đã được xóa khỏi danh sách',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Không thể xóa địa chỉ',
        message: e.toString(),
      );
    }
  }

  ///
  Future<dynamic> selectNewAddressPopup(BuildContext context) => showModalBottomSheet(
    context: context, isScrollControlled: true, useSafeArea: true, showDragHandle: false,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => const AddressSelectionSheet(),
  );

  void resetFormFields() {
    location.value = null;
    name.clear();
    phoneNumber.clear();
    street.clear();
    city.clear();
    state.clear();
    country.clear();
    addressFormKey.currentState?.reset();
  }
}