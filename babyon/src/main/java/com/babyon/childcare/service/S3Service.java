package com.babyon.childcare.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.*;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;
import software.amazon.awssdk.services.s3.presigner.model.PresignedGetObjectRequest;

import java.io.IOException;
import java.time.Duration;
import java.util.UUID;

/**
 * AWS S3 파일 업로드/다운로드 서비스
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class S3Service {

    private final S3Client s3Client;
    private final S3Presigner s3Presigner;

    @Value("${aws.s3.bucket-name}")
    private String bucketName;

    /**
     * 파일 업로드
     * @param file 업로드할 파일
     * @param folder S3 내 폴더 경로 (예: "videos/intro", "videos/answer")
     * @return 업로드된 파일의 S3 키 (경로)
     */
    public String uploadFile(MultipartFile file, String folder) {
        String originalFilename = file.getOriginalFilename();
        String extension = originalFilename != null && originalFilename.contains(".")
            ? originalFilename.substring(originalFilename.lastIndexOf("."))
            : "";

        String fileName = UUID.randomUUID().toString() + extension;
        String key = folder + "/" + fileName;

        try {
            PutObjectRequest putObjectRequest = PutObjectRequest.builder()
                .bucket(bucketName)
                .key(key)
                .contentType(file.getContentType())
                .contentLength(file.getSize())
                .build();

            s3Client.putObject(putObjectRequest,
                RequestBody.fromInputStream(file.getInputStream(), file.getSize()));

            log.info("파일 업로드 성공: bucket={}, key={}", bucketName, key);
            return key;

        } catch (IOException e) {
            log.error("파일 업로드 실패: {}", e.getMessage(), e);
            throw new RuntimeException("파일 업로드에 실패했습니다.", e);
        } catch (S3Exception e) {
            log.error("S3 업로드 오류: {}", e.awsErrorDetails().errorMessage(), e);
            throw new RuntimeException("S3 업로드 중 오류가 발생했습니다.", e);
        }
    }

    /**
     * Presigned URL 생성 (다운로드용 임시 URL, 1시간 유효)
     * @param key S3 객체 키
     * @return Presigned URL
     */
    public String generatePresignedUrl(String key) {
        return generatePresignedUrl(key, Duration.ofHours(1));
    }

    /**
     * Presigned URL 생성 (사용자 정의 만료 시간)
     * @param key S3 객체 키
     * @param duration URL 유효 기간
     * @return Presigned URL
     */
    public String generatePresignedUrl(String key, Duration duration) {
        try {
            GetObjectRequest getObjectRequest = GetObjectRequest.builder()
                .bucket(bucketName)
                .key(key)
                .build();

            GetObjectPresignRequest presignRequest = GetObjectPresignRequest.builder()
                .signatureDuration(duration)
                .getObjectRequest(getObjectRequest)
                .build();

            PresignedGetObjectRequest presignedRequest = s3Presigner.presignGetObject(presignRequest);
            String url = presignedRequest.url().toString();

            log.debug("Presigned URL 생성: key={}, duration={}", key, duration);
            return url;

        } catch (S3Exception e) {
            log.error("Presigned URL 생성 실패: {}", e.awsErrorDetails().errorMessage(), e);
            throw new RuntimeException("Presigned URL 생성에 실패했습니다.", e);
        }
    }

    /**
     * 파일 삭제
     * @param key S3 객체 키
     */
    public void deleteFile(String key) {
        try {
            DeleteObjectRequest deleteObjectRequest = DeleteObjectRequest.builder()
                .bucket(bucketName)
                .key(key)
                .build();

            s3Client.deleteObject(deleteObjectRequest);
            log.info("파일 삭제 성공: bucket={}, key={}", bucketName, key);

        } catch (S3Exception e) {
            log.error("파일 삭제 실패: {}", e.awsErrorDetails().errorMessage(), e);
            throw new RuntimeException("파일 삭제에 실패했습니다.", e);
        }
    }

    /**
     * 파일 존재 여부 확인
     * @param key S3 객체 키
     * @return 파일 존재 여부
     */
    public boolean fileExists(String key) {
        try {
            HeadObjectRequest headObjectRequest = HeadObjectRequest.builder()
                .bucket(bucketName)
                .key(key)
                .build();

            s3Client.headObject(headObjectRequest);
            return true;

        } catch (NoSuchKeyException e) {
            return false;
        } catch (S3Exception e) {
            log.error("파일 존재 확인 실패: {}", e.awsErrorDetails().errorMessage(), e);
            return false;
        }
    }

    /**
     * 파일 크기 조회 (bytes)
     * @param key S3 객체 키
     * @return 파일 크기
     */
    public Long getFileSize(String key) {
        try {
            HeadObjectRequest headObjectRequest = HeadObjectRequest.builder()
                .bucket(bucketName)
                .key(key)
                .build();

            HeadObjectResponse response = s3Client.headObject(headObjectRequest);
            return response.contentLength();

        } catch (S3Exception e) {
            log.error("파일 크기 조회 실패: {}", e.awsErrorDetails().errorMessage(), e);
            throw new RuntimeException("파일 크기 조회에 실패했습니다.", e);
        }
    }
}
