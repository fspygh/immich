import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';
import 'package:immich_mobile/modules/shared_link/models/shared_link.dart';
import 'package:immich_mobile/modules/shared_link/providers/shared_link.provider.dart';
import 'package:immich_mobile/modules/shared_link/services/shared_link.service.dart';
import 'package:immich_mobile/shared/ui/immich_toast.dart';
import 'package:immich_mobile/utils/url_helper.dart';

class SharedLinkEditPage extends HookConsumerWidget {
  final SharedLink? existingLink;
  final List<String>? assetsList;
  final String? albumId;

  const SharedLinkEditPage({
    super.key,
    this.existingLink,
    this.assetsList,
    this.albumId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const padding = 20.0;
    final themeData = context.themeData;
    final descriptionController =
        useTextEditingController(text: existingLink?.description ?? "");
    final descriptionFocusNode = useFocusNode();
    final passwordController =
        useTextEditingController(text: existingLink?.password ?? "");
    final showMetadata = useState(existingLink?.showMetadata ?? true);
    final allowDownload = useState(existingLink?.allowDownload ?? true);
    final allowUpload = useState(existingLink?.allowUpload ?? false);
    final editExpiry = useState(false);
    final expiryAfter = useState(0);
    final newShareLink = useState("");

    Widget buildLinkTitle() {
      if (existingLink != null) {
        if (existingLink!.type == SharedLinkSource.album) {
          return Row(
            children: [
              const Text(
                "Public album | ",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                existingLink!.title,
                style: TextStyle(
                  color: themeData.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
        }

        if (existingLink!.type == SharedLinkSource.individual) {
          return Row(
            children: [
              const Text(
                "Individual shared | ",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: Text(
                  existingLink!.description ?? "--",
                  style: TextStyle(
                    color: themeData.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        }
      }

      return const Text(
        "shared_link_create_info",
        style: TextStyle(fontWeight: FontWeight.bold),
      ).tr();
    }

    Widget buildDescriptionField() {
      return TextField(
        controller: descriptionController,
        enabled: newShareLink.value.isEmpty,
        focusNode: descriptionFocusNode,
        textInputAction: TextInputAction.done,
        autofocus: false,
        decoration: InputDecoration(
          labelText: 'shared_link_edit_description'.tr(),
          labelStyle: TextStyle(
            fontWeight: FontWeight.bold,
            color: themeData.primaryColor,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          border: const OutlineInputBorder(),
          hintText: 'shared_link_edit_description_hint'.tr(),
          hintStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 14,
          ),
          disabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.5)),
          ),
        ),
        onTapOutside: (_) => descriptionFocusNode.unfocus(),
      );
    }

    Widget buildPasswordField() {
      return TextField(
        controller: passwordController,
        enabled: newShareLink.value.isEmpty,
        autofocus: false,
        decoration: InputDecoration(
          labelText: 'shared_link_edit_password'.tr(),
          labelStyle: TextStyle(
            fontWeight: FontWeight.bold,
            color: themeData.primaryColor,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          border: const OutlineInputBorder(),
          hintText: 'shared_link_edit_password_hint'.tr(),
          hintStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 14,
          ),
          disabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.5)),
          ),
        ),
      );
    }

    Widget buildShowMetaButton() {
      return SwitchListTile.adaptive(
        value: showMetadata.value,
        onChanged: newShareLink.value.isEmpty
            ? (value) => showMetadata.value = value
            : null,
        activeColor: themeData.primaryColor,
        dense: true,
        title: Text(
          "shared_link_edit_show_meta",
          style: themeData.textTheme.labelLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ).tr(),
      );
    }

    Widget buildAllowDownloadButton() {
      return SwitchListTile.adaptive(
        value: allowDownload.value,
        onChanged: newShareLink.value.isEmpty
            ? (value) => allowDownload.value = value
            : null,
        activeColor: themeData.primaryColor,
        dense: true,
        title: Text(
          "shared_link_edit_allow_download",
          style: themeData.textTheme.labelLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ).tr(),
      );
    }

    Widget buildAllowUploadButton() {
      return SwitchListTile.adaptive(
        value: allowUpload.value,
        onChanged: newShareLink.value.isEmpty
            ? (value) => allowUpload.value = value
            : null,
        activeColor: themeData.primaryColor,
        dense: true,
        title: Text(
          "shared_link_edit_allow_upload",
          style: themeData.textTheme.labelLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ).tr(),
      );
    }

    Widget buildEditExpiryButton() {
      return SwitchListTile.adaptive(
        value: editExpiry.value,
        onChanged: newShareLink.value.isEmpty
            ? (value) => editExpiry.value = value
            : null,
        activeColor: themeData.primaryColor,
        dense: true,
        title: Text(
          "shared_link_edit_change_expiry",
          style: themeData.textTheme.labelLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ).tr(),
      );
    }

    Widget buildExpiryAfterButton() {
      return DropdownMenu(
        label: Text(
          "shared_link_edit_expire_after",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: themeData.primaryColor,
          ),
        ).tr(),
        enableSearch: false,
        enableFilter: false,
        width: context.width - 40,
        initialSelection: expiryAfter.value,
        enabled: newShareLink.value.isEmpty &&
            (existingLink == null || editExpiry.value),
        onSelected: (value) {
          expiryAfter.value = value!;
        },
        inputDecorationTheme: themeData.inputDecorationTheme.copyWith(
          disabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.5)),
          ),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
        ),
        dropdownMenuEntries: [
          DropdownMenuEntry(
            value: 0,
            label: "shared_link_edit_expire_after_option_never".tr(),
          ),
          DropdownMenuEntry(
            value: 30,
            label:
                "shared_link_edit_expire_after_option_minutes".tr(args: ["30"]),
          ),
          DropdownMenuEntry(
            value: 60,
            label: "shared_link_edit_expire_after_option_hour".tr(),
          ),
          DropdownMenuEntry(
            value: 60 * 6,
            label: "shared_link_edit_expire_after_option_hours".tr(args: ["6"]),
          ),
          DropdownMenuEntry(
            value: 60 * 24,
            label: "shared_link_edit_expire_after_option_day".tr(),
          ),
          DropdownMenuEntry(
            value: 60 * 24 * 7,
            label: "shared_link_edit_expire_after_option_days".tr(args: ["7"]),
          ),
          DropdownMenuEntry(
            value: 60 * 24 * 30,
            label: "shared_link_edit_expire_after_option_days".tr(args: ["30"]),
          ),
        ],
      );
    }

    void copyLinkToClipboard() {
      Clipboard.setData(
        ClipboardData(
          text: passwordController.text.isEmpty
              ? newShareLink.value
              : "shared_link_clipboard_text".tr(
                  args: [newShareLink.value, passwordController.text],
                ),
        ),
      ).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "shared_link_clipboard_copied_massage",
              style: context.textTheme.bodyLarge?.copyWith(
                color: context.primaryColor,
              ),
            ).tr(),
            duration: const Duration(seconds: 2),
          ),
        );
      });
    }

    Widget buildNewLinkField() {
      return Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(
              top: 20,
              bottom: 20,
            ),
            child: Divider(),
          ),
          TextFormField(
            readOnly: true,
            initialValue: newShareLink.value,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              enabledBorder: themeData.inputDecorationTheme.focusedBorder,
              suffixIcon: IconButton(
                onPressed: copyLinkToClipboard,
                icon: const Icon(Icons.copy),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                onPressed: () {
                  context.autoPop();
                },
                child: const Text(
                  "share_done",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ).tr(),
              ),
            ),
          ),
        ],
      );
    }

    DateTime calculateExpiry() {
      return DateTime.now().add(Duration(minutes: expiryAfter.value));
    }

    Future<void> handleNewLink() async {
      final newLink =
          await ref.read(sharedLinkServiceProvider).createSharedLink(
                albumId: albumId,
                assetIds: assetsList,
                showMeta: showMetadata.value,
                allowDownload: allowDownload.value,
                allowUpload: allowUpload.value,
                description: descriptionController.text.isEmpty
                    ? null
                    : descriptionController.text,
                password: passwordController.text.isEmpty
                    ? null
                    : passwordController.text,
                expiresAt: expiryAfter.value == 0 ? null : calculateExpiry(),
              );
      ref.invalidate(sharedLinksStateProvider);
      final serverUrl = getServerUrl();
      if (newLink != null && serverUrl != null) {
        newShareLink.value = "$serverUrl/share/${newLink.key}";
        copyLinkToClipboard();
      } else if (newLink == null) {
        ImmichToast.show(
          context: context,
          gravity: ToastGravity.BOTTOM,
          toastType: ToastType.error,
          msg: 'shared_link_create_error'.tr(),
        );
      }
    }

    Future<void> handleEditLink() async {
      bool? download;
      bool? upload;
      bool? meta;
      String? desc;
      String? password;
      DateTime? expiry;
      bool? changeExpiry;

      if (allowDownload.value != existingLink!.allowDownload) {
        download = allowDownload.value;
      }

      if (allowUpload.value != existingLink!.allowUpload) {
        upload = allowUpload.value;
      }

      if (showMetadata.value != existingLink!.showMetadata) {
        meta = showMetadata.value;
      }

      if (descriptionController.text != existingLink!.description) {
        desc = descriptionController.text;
      }

      if (passwordController.text != existingLink!.password) {
        password = passwordController.text;
      }

      if (editExpiry.value) {
        expiry = expiryAfter.value == 0 ? null : calculateExpiry();
        changeExpiry = true;
      }

      await ref.read(sharedLinkServiceProvider).updateSharedLink(
            existingLink!.id,
            showMeta: meta,
            allowDownload: download,
            allowUpload: upload,
            description: desc,
            password: password,
            expiresAt: expiry,
            changeExpiry: changeExpiry,
          );
      ref.invalidate(sharedLinksStateProvider);
      context.autoPop();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          existingLink == null
              ? "shared_link_create_app_bar_title"
              : "shared_link_edit_app_bar_title",
        ).tr(),
        elevation: 0,
        leading: const CloseButton(),
        centerTitle: false,
      ),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(padding),
              child: buildLinkTitle(),
            ),
            Padding(
              padding: const EdgeInsets.all(padding),
              child: buildDescriptionField(),
            ),
            Padding(
              padding: const EdgeInsets.all(padding),
              child: buildPasswordField(),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: padding,
                right: padding,
                bottom: padding,
              ),
              child: buildShowMetaButton(),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: padding,
                right: padding,
                bottom: padding,
              ),
              child: buildAllowDownloadButton(),
            ),
            Padding(
              padding:
                  const EdgeInsets.only(left: padding, right: 20, bottom: 20),
              child: buildAllowUploadButton(),
            ),
            if (existingLink != null)
              Padding(
                padding: const EdgeInsets.only(
                  left: padding,
                  right: padding,
                  bottom: padding,
                ),
                child: buildEditExpiryButton(),
              ),
            Padding(
              padding: const EdgeInsets.only(
                left: padding,
                right: padding,
                bottom: padding,
              ),
              child: buildExpiryAfterButton(),
            ),
            if (newShareLink.value.isEmpty)
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: padding + 10),
                  child: ElevatedButton(
                    onPressed:
                        existingLink != null ? handleEditLink : handleNewLink,
                    child: Text(
                      existingLink != null
                          ? "shared_link_edit_submit_button"
                          : "shared_link_create_submit_button",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ).tr(),
                  ),
                ),
              ),
            if (newShareLink.value.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(
                  left: padding,
                  right: padding,
                ),
                child: buildNewLinkField(),
              ),
          ],
        ),
      ),
    );
  }
}
