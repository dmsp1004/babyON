package com.babyon.childcare.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.AwsCredentialsProvider;
import software.amazon.awssdk.auth.credentials.DefaultCredentialsProvider;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;

/**
 * AWS S3 클라이언트 설정
 * 환경 변수가 있으면 Static Credentials 사용, 없으면 IAM Role 사용 (Default Credentials Chain)
 */
@Configuration
public class AwsConfig {

    @Value("${aws.access-key-id:}")
    private String accessKeyId;

    @Value("${aws.secret-access-key:}")
    private String secretAccessKey;

    @Value("${aws.s3.region}")
    private String region;

    /**
     * AWS 자격증명 제공자 생성
     * 개발 환경: 환경 변수로 제공된 액세스 키 사용
     * 프로덕션 환경: IAM Role 사용 (EC2, ECS 등)
     */
    private AwsCredentialsProvider getCredentialsProvider() {
        if (accessKeyId != null && !accessKeyId.isEmpty() &&
            secretAccessKey != null && !secretAccessKey.isEmpty()) {
            // 환경 변수가 있으면 Static Credentials 사용 (개발 환경)
            AwsBasicCredentials awsCredentials = AwsBasicCredentials.create(
                accessKeyId,
                secretAccessKey
            );
            return StaticCredentialsProvider.create(awsCredentials);
        } else {
            // 환경 변수가 없으면 Default Credentials Chain 사용 (IAM Role)
            // EC2, ECS, Lambda 등에서 자동으로 IAM Role에서 자격증명 로드
            return DefaultCredentialsProvider.create();
        }
    }

    /**
     * S3 클라이언트 빈 생성
     */
    @Bean
    public S3Client s3Client() {
        return S3Client.builder()
            .region(Region.of(region))
            .credentialsProvider(getCredentialsProvider())
            .build();
    }

    /**
     * S3 Presigner 빈 생성 (Presigned URL 생성용)
     */
    @Bean
    public S3Presigner s3Presigner() {
        return S3Presigner.builder()
            .region(Region.of(region))
            .credentialsProvider(getCredentialsProvider())
            .build();
    }
}
