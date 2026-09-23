 import 'package:arunika_app/data/models/response/signup_response.dart';
import 'package:arunika_app/data/models/response/user_response.dart';

class UserResponseConverter {
   static UserResponse toUserResponse(SignUpResponse signUpResponse) {
     return UserResponse(
       id: signUpResponse.id,
       name: signUpResponse.name,
       phoneNumber: signUpResponse.phoneNumber,
       emailAddress: signUpResponse.email,
       address: signUpResponse.address,
       city: signUpResponse.city,
       children: signUpResponse.children,
       // A just-registered account has not verified its address yet. The
       // field defaults to true elsewhere (so a profile from a backend
       // predating it never nags an existing user), but here we know better.
       emailVerified: false,
     );
   }
 }