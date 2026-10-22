@{
  Replacements = @(
    @{
      Path = "lib\page\platform_subpage.dart"
      Find = "              middle: MediaQuery("
      Replace = "              title: MediaQuery("
    }
    @{
      Path = "lib\widget\libraries\platform_app_bar_ex.dart"
      Find = "      middle: MediaQuery("
      Replace = "      title: MediaQuery("
    }
    @{
      Path = "lib\util\noticing.dart"
      Find = "        persist: false, // https://docs.flutter.dev/release/breaking-changes/snackbar-with-action-behavior-update`r`n"
      Replace = ""
    }
  )
}
