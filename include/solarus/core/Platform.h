#ifndef SOLARUS_PLATFORM_H
#define SOLARUS_PLATFORM_H

#include <algorithm>
#include <string>

// ----------------------------------------------------------------------
// IsRunningOnXbox
// Determines whether or not the game is running on an xbox console
static bool IsRunningOnXbox()
{
	// Skip if already checked
	static bool bChecked = false;
	static bool bRunningOnXbox = false;
	if (bChecked)
		return bRunningOnXbox;

	// Retrieve the platform device family
	Platform::String^ strVersionInfoDeviceFamily = Windows::System::Profile::AnalyticsInfo::VersionInfo->DeviceFamily;
	if (strVersionInfoDeviceFamily != nullptr)
	{
		// Check to see if the device belongs to the xbox family
		std::wstring strDeviceFamily = strVersionInfoDeviceFamily->Data();
		std::transform(strDeviceFamily.begin(), strDeviceFamily.end(), strDeviceFamily.begin(), ::tolower);
		if (strDeviceFamily.find(L"xbox") != std::wstring::npos)
			bRunningOnXbox = true;
	}

	// Check complete
	bChecked = true;

	// Return whether or not the host platform is xbox
	return bRunningOnXbox;
}

#endif