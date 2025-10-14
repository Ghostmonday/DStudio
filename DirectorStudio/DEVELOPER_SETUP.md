# DirectorStudio Developer Setup Guide

## API Key Configuration

DirectorStudio uses DeepSeek AI for story processing. The API key must be configured securely by the developer before building the app.

### Method 1: .xcconfig Configuration (Recommended)

1. Open `DirectorStudio/Secrets.xcconfig`
2. Replace `"YOUR_DEEPSEEK_API_KEY_HERE"` with your actual DeepSeek API key:

```text
DEEPSEEK_API_KEY = "sk-your-actual-deepseek-api-key-here"
```

3. In Xcode, go to **Project Settings → Build Settings → Configurations**
4. Add `Secrets.xcconfig` to your Debug and Release configurations

### Method 2: Environment Variables (For Development)

1. In Xcode, go to **Product → Scheme → Edit Scheme**
2. Select **Run → Arguments → Environment Variables**
3. Add:
   - Name: `DEEPSEEK_API_KEY`
   - Value: `sk-your-actual-deepseek-api-key-here`

### Getting Your DeepSeek API Key

1. Visit [DeepSeek Platform](https://platform.deepseek.com/)
2. Sign up or log in to your account
3. Navigate to the API section
4. Create a new API key
5. Copy the key and use it in one of the methods above

### Security Best Practices

- **Never commit API keys to version control**
- **Never put API keys in Info.plist or source code**
- Use `.xcconfig` files for build-time configuration
- Use environment variables in CI/CD pipelines
- Consider using key management services for production
- Rotate API keys regularly
- Ensure `Secrets.xcconfig` is in `.gitignore`

### Validation

The app will automatically validate the API key configuration on launch. Check the console output for:

- ✅ `DeepSeek API key configured securely` - Success
- ❌ `DeepSeek API key not configured` - Needs configuration
- ⚠️ `SECURITY WARNING: Using placeholder API key` - Still using placeholder

### Troubleshooting

**Issue**: AI features not working
**Solution**: Ensure the API key is properly configured using one of the methods above

**Issue**: Build errors
**Solution**: Make sure the API key string is properly quoted and escaped

**Issue**: API requests failing
**Solution**: Verify the API key is valid and has sufficient credits

## Build Configuration

### Xcode Project Settings

1. Open `DirectorStudio.xcodeproj` in Xcode
2. Select the project in the navigator
3. Go to Build Settings
4. Ensure the following are configured:
   - iOS Deployment Target: 17.0+
   - Mac Catalyst: Enabled
   - Bundle Identifier: `com.directorstudio.app`

### Required Capabilities

- Network access for API calls
- File sharing for export features
- No special permissions required

## Testing

### Simulator Testing

1. Configure API key using Method 1
2. Build and run in iOS Simulator
3. Test AI pipeline with sample story
4. Verify all 6 modules execute successfully

### Device Testing

1. Configure API key
2. Build for device
3. Test on physical iPhone/iPad
4. Verify Mac Catalyst functionality on Mac

## Production Deployment

### App Store Preparation

1. Ensure API key is properly configured
2. Test all features thoroughly
3. Update version numbers
4. Prepare privacy policy and app description
5. Submit for review

### Privacy Compliance

- No user data collection
- API key embedded securely
- Story content processed temporarily
- No persistent storage of user content

## Support

For technical support or questions about API key configuration, please refer to the DeepSeek documentation or contact the development team.
