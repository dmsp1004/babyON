package com.babyon.childcare;

import com.babyon.childcare.config.SecurityConfig;
import com.babyon.childcare.config.TestSecurityConfig;
import com.babyon.childcare.oauth.CustomOAuth2UserService;
import com.babyon.childcare.oauth.OAuth2SuccessHandler;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest(properties = {
    "spring.autoconfigure.exclude=org.springframework.boot.autoconfigure.security.oauth2.client.servlet.OAuth2ClientAutoConfiguration"
})
@Import(TestSecurityConfig.class)
@ActiveProfiles("test")
class ChildcareApplicationTests {

	@MockBean
	private CustomOAuth2UserService customOAuth2UserService;

	@MockBean
	private OAuth2SuccessHandler oAuth2SuccessHandler;

	@Test
	void contextLoads() {
	}

}
