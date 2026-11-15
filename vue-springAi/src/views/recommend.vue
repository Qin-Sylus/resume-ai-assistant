<template>
  <div class="recommend-container">
    <div class="header">
      <p>基于您的简历和技能，为您推荐最匹配的职位</p>
    </div>

    <div v-if="loading" class="loading-container">
      <div class="loading-spinner"></div>
      <p>正在获取推荐职位...</p>
    </div>

    <div v-if="errorMessage" class="error-message">
      {{ errorMessage }}
    </div>

    <!-- 职业发展建议部分 -->
    <div v-if="careerAdvice && !loading" class="career-advice-section">
      <h2>职业发展建议</h2>
      <div class="advice-container">
        <div class="advice-card">
          <div class="advice-icon">🎯</div>
          <div class="advice-content">
            <h3>短期目标 (1年内)</h3>
            <p>{{ careerAdvice.short_term }}</p>
          </div>
        </div>
        <div class="advice-card">
          <div class="advice-icon">💡</div>
          <div class="advice-content">
            <h3>技能提升建议</h3>
            <p>{{ careerAdvice.skills_improvement }}</p>
          </div>
        </div>
        <div class="advice-card">
          <div class="advice-icon">🚀</div>
          <div class="advice-content">
            <h3>长期职业规划 (3-5年)</h3>
            <p>{{ careerAdvice.long_term }}</p>
          </div>
        </div>
      </div>
    </div>

    <div v-if="recommendedJobs.length > 0" class="results-section">
      <h2>为您推荐的职位 ({{ recommendedJobs.length }})</h2>
      <div class="job-list">
        <div 
          v-for="job in recommendedJobs" 
          :key="job.id" 
          class="job-card"
        >
          <div class="job-header">
            <h3>{{ job.title }}</h3>
            <span class="match-score">匹配度: {{ job.matchScore }}%</span>
          </div>
          
          <!-- 添加AI生成的推荐理由 -->
          <div v-if="job.recommendation_reason" class="job-recommendation">
            <div class="recommendation-title">🔍 推荐理由</div>
            <p>{{ job.recommendation_reason }}</p>
          </div>

          <div class="job-details">
            <p><strong>公司:</strong> {{ job.company_name }}</p>
            <p><strong>薪资范围:</strong> {{ job.salary_range }}</p>
            <p><strong>地点:</strong> {{ job.location }}</p>
            <p><strong>学历要求:</strong> {{ job.education_requirements }}</p>
            <p><strong>经验要求:</strong> {{ job.experience_requirements }}</p>
          </div>
          
          <!-- 添加简历优化建议 -->
          <div v-if="job.resume_improvement" class="resume-improvement">
            <div class="improvement-title">💼 简历优化建议</div>
            <p>{{ job.resume_improvement }}</p>
          </div>
          
          <div class="job-actions">
            <button class="apply-button">申请职位</button>
            <button class="save-button">收藏</button>
          </div>
        </div>
      </div>
    </div>

    <div v-else-if="!loading && searched" class="no-results">
      <p>没有找到匹配的职位，请完善您的简历信息以获得更准确的推荐</p>
      <button @click="goToResume" class="action-button primary">完善简历</button>
    </div>
  </div>
</template>

<script>
import axios from 'axios'

export default {
  name: 'RecommendView',
  data() {
    return {
      recommendedJobs: [],
      careerAdvice: null,
      loading: true,
      searched: false,
      errorMessage: ''
    }
  },
  created() {
    this.getRecommendations();
  },
  methods: {
    async getRecommendations() {
      // 检查用户是否登录
      const userId = localStorage.getItem('userId');
      if (!userId) {
        this.errorMessage = '请先登录以获取职位推荐';
        this.loading = false;
        return;
      }
      
      this.loading = true;
      this.errorMessage = '';
      
      try {
        // 直接发送请求，仅传递用户ID
        const response = await axios.post('http://localhost:9090/api/recommend/jobs', { userId });
        
        // 检查响应格式，适应新的后端返回结构
        if (response.data) {
          if (response.data.jobs) {
            // 新格式：包含职位列表和职业建议
            this.recommendedJobs = response.data.jobs.map(job => {
              const normalizedScore = Math.min(job.matchScore, 100);
              return { ...job, matchScore: normalizedScore };
            });
            
            // 设置职业建议
            this.careerAdvice = response.data.career_advice;
          } else if (Array.isArray(response.data)) {
            // 旧格式：直接返回职位列表
            this.recommendedJobs = response.data.map(job => {
              const normalizedScore = Math.min(job.matchScore, 100);
              return { ...job, matchScore: normalizedScore };
            });
          } else {
            this.recommendedJobs = [];
          }
        } else {
          this.recommendedJobs = [];
        }
        
        this.searched = true;
      } catch (error) {
        console.error('Error fetching job recommendations:', error);
        if (error.response?.status === 404) {
          this.errorMessage = '未找到您的简历信息，请先完善简历';
        } else {
          this.errorMessage = error.response?.data?.error || '加载职位推荐时出错，请稍后再试';
        }
        this.recommendedJobs = [];
      } finally {
        this.loading = false;
      }
    },
    goToResume() {
      this.$router.push('/resume');
    }
  }
}
</script>

<style scoped>
.recommend-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
  font-family: 'Arial', sans-serif;
}

.header {
  text-align: center;
  margin-bottom: 30px;
}

.header h1 {
  color: #2c3e50;
  margin-bottom: 10px;
}

.header p {
  color: #7f8c8d;
  font-size: 16px;
}

/* 职业建议卡片样式 */
.career-advice-section {
  margin-bottom: 40px;
  background-color: #f8f9fa;
  border-radius: 12px;
  padding: 25px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.05);
}

.career-advice-section h2 {
  color: #2c3e50;
  margin-bottom: 20px;
  text-align: center;
  font-size: 22px;
}

.advice-container {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 20px;
}

.advice-card {
  background-color: white;
  border-radius: 8px;
  padding: 20px;
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.1);
  display: flex;
  align-items: flex-start;
}

.advice-icon {
  font-size: 24px;
  margin-right: 15px;
  padding-top: 5px;
}

.advice-content h3 {
  color: #3498db;
  margin-top: 0;
  margin-bottom: 10px;
  font-size: 18px;
}

.advice-content p {
  color: #34495e;
  line-height: 1.5;
  margin: 0;
}

.loading-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  margin: 50px 0;
}

.loading-spinner {
  border: 4px solid #f3f3f3;
  border-top: 4px solid #3498db;
  border-radius: 50%;
  width: 40px;
  height: 40px;
  animation: spin 2s linear infinite;
  margin-bottom: 15px;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.error-message {
  background-color: #f8d7da;
  color: #721c24;
  padding: 20px;
  border-radius: 8px;
  margin: 40px auto;
  text-align: center;
  max-width: 600px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.results-section h2 {
  margin-bottom: 20px;
  color: #2c3e50;
  border-bottom: 2px solid #3498db;
  padding-bottom: 10px;
}

.job-list {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
  gap: 25px;
}

.job-card {
  background-color: white;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 4px 10px rgba(0, 0, 0, 0.1);
  transition: transform 0.3s;
}

.job-card:hover {
  transform: translateY(-5px);
}

.job-header {
  background-color: #3498db;
  color: white;
  padding: 15px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.job-header h3 {
  margin: 0;
  font-size: 18px;
}

.match-score {
  background-color: rgba(255, 255, 255, 0.2);
  padding: 5px 10px;
  border-radius: 15px;
  font-weight: 600;
  font-size: 14px;
}

.job-recommendation {
  background-color: #edf7ff;
  padding: 15px;
  border-left: 4px solid #3498db;
  margin: 15px;
  border-radius: 4px;
}

.recommendation-title {
  color: #2980b9;
  font-weight: 600;
  margin-bottom: 5px;
}

.job-details {
  padding: 15px;
}

.job-details p {
  margin: 10px 0;
  color: #34495e;
}

.resume-improvement {
  background-color: #f0f9eb;
  padding: 15px;
  border-left: 4px solid #67c23a;
  margin: 0 15px 15px;
  border-radius: 4px;
}

.improvement-title {
  color: #5daf34;
  font-weight: 600;
  margin-bottom: 5px;
}

.job-actions {
  display: flex;
  padding: 15px;
  border-top: 1px solid #ecf0f1;
}

.apply-button, .save-button {
  padding: 8px 12px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-weight: 600;
  font-size: 14px;
}

.apply-button {
  background-color: #2ecc71;
  color: white;
  margin-right: 10px;
  flex: 1;
}

.apply-button:hover {
  background-color: #27ae60;
}

.save-button {
  background-color: #ecf0f1;
  color: #34495e;
  flex: 1;
}

.save-button:hover {
  background-color: #bdc3c7;
}

.no-results {
  text-align: center;
  padding: 40px;
  background-color: #f9f9f9;
  border-radius: 8px;
  margin-top: 20px;
}

.no-results p {
  color: #7f8c8d;
  font-size: 18px;
  margin-bottom: 20px;
}

.action-button {
  padding: 10px 20px;
  border-radius: 4px;
  cursor: pointer;
  font-weight: 600;
  border: none;
  transition: background-color 0.3s;
}

.primary {
  background-color: #3498db;
  color: white;
}

.primary:hover {
  background-color: #2980b9;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .job-list, .advice-container {
    grid-template-columns: 1fr;
  }
}
</style>
