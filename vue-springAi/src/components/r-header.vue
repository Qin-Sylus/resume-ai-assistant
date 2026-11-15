<template>
  <div class="header-container">
    <div class="header-left">
      欢迎登录职达助手！
    </div>

    <el-button type="primary" plain @click="showMyResume" class="action-button" style="margin-right: 10px">
      我的简历
    </el-button>
    <el-button type="primary" plain @click="showResumeModal = true" class="action-button" style="margin-right: 10px">
      简历AI
    </el-button>

    <!-- 根据 username 判断是否显示按钮 -->
    <el-button 
      v-if="isAdmin" 
      type="success" 
      plain 
      @click="clickJobPool"
    >
    职位库管理
    </el-button>

    <el-button 
      v-if="!isAdmin" 
      type="success" 
      plain 
      @click="clickRecommend"
    >
    推荐职位
    </el-button>

    <el-popconfirm
      confirmButtonText="好的"
      cancelButtonText="不用了"
      icon="el-icon-info"
      icon-color="red"
      title="确定退出登录吗？"
      @confirm="handleLogout"
    >
      <template #reference>
        <el-button type="danger" class="logout-button" round>
          退出登录
        </el-button>
      </template>
    </el-popconfirm>

    <!-- 【新增】简历弹窗 -->
    <el-dialog v-model="showResumeModal" title="请选择简历模板" width="400px" :close-on-click-modal="false" center>
      <div class="version-select">
        <el-radio-group v-model="resumeVersion" size="small">
          <el-radio-button label="应届生版" />
          <el-radio-button label="标准版" />
        </el-radio-group>
      </div>
      <div v-if="resumeVersion === '应届生版'" class="resume-form">
        <el-form :model="form" label-width="80px">
          <el-form-item label="我的专业">
            <el-input v-model="form.major" maxlength="20" show-word-limit placeholder="请输入专业" />
          </el-form-item>
          <el-form-item label="期望职位">
            <el-input v-model="form.position" maxlength="20" show-word-limit placeholder="请输入职位" />
          </el-form-item>
          <el-form-item label="我的补充">
            <el-input v-model="form.extra" maxlength="40" show-word-limit type="textarea" placeholder="补充内容" />
          </el-form-item>
        </el-form>
      </div>
      <div v-if="resumeVersion === '标准版'" class="resume-form">
        <el-form :model="form" label-width="80px">
          <el-form-item label="工作经历">
            <el-input v-model="form.experience" maxlength="20" show-word-limit placeholder="请输入经历" />
          </el-form-item>
          <el-form-item label="期望职位">
            <el-input v-model="form.position" maxlength="20" show-word-limit placeholder="请输入职位" />
          </el-form-item>
          <el-form-item label="我的补充">
            <el-input v-model="form.extra" maxlength="40" show-word-limit type="textarea" placeholder="补充内容" />
          </el-form-item>
        </el-form>
      </div>
      <!-- 底部按钮 -->
      <template #footer>
        <span class="dialog-footer">
          <el-button 
            @click="generateResume" 
            type="primary" 
            :loading="generating"
            :disabled="!isFormValid"
          >
            {{ generating ? '正在生成简历...' : '生成' }}
          </el-button>
        </span>
      </template>
    </el-dialog>

    <!-- 生成状态提示 -->
    <el-dialog
      v-model="showGeneratingDialog"
      :show-close="false"
      width="300px"
      center
    >
      <div class="generating-status">
        <el-progress 
          type="circle"
          :indeterminate="true"
          :duration="1"
          :stroke-width="4"
          status="warning"
        />
        <p class="status-text">{{ statusText }}</p>
      </div>
    </el-dialog>
  </div>
</template>

<script>
export default {
  name: 'r-header',
  data() {
    return {
      username: null,
      isAdmin: false, // 默认不显示心理分析按钮
      // ▼▼▼ 新增以下三个关键变量 ▼▼▼
      showResumeModal: false,  // 控制弹窗显示
      resumeVersion: '应届生版', // 默认选中的简历版本
      form: {                  // 表单数据模型
        major: '',
        position: '',
        extra: '',
        experience: ''
      },
      generating: false,
      showGeneratingDialog: false,
      statusText: ''
    };
  },
  computed: {
    isFormValid() {
      if (this.resumeVersion === '应届生版') {
        return this.form.major && this.form.position;
      }
      return this.form.experience && this.form.position;
    }
  },
  created() {
    this.username = localStorage.getItem('username');
    // 如果 username 为管理员，显示按钮
    if (this.username === '管理员') {
      this.isAdmin = true;
    }
  },
  methods: {
    clickJobPool() {
      this.$router.push('/jobPool');
    },
    clickRecommend() {
      this.$router.push('/recommend');
    },
    handleLogout() {
      localStorage.clear();
      this.$router.push('/login');
    },
    goToHome() {
      this.$router.push('/');
    },
    showMyResume() {
      // 清除本地存储的简历数据，以便加载最新的数据库数据
      localStorage.removeItem('resumeData');
      this.$router.push('/resume'); 
    },
    goToProfile() {
      this.$router.push('/profile');
    },
    // ✅ 新增：生成简历逻辑（你可以替换为调用后端接口）
    async generateResume() {
      if (!this.isFormValid) {
        this.$message.warning('请填写必要信息');
        return;
      }

      this.generating = true;
      this.showGeneratingDialog = true;
      this.statusText = '正在生成简历...';

      try {
        const userId = localStorage.getItem('userId');
        const username = localStorage.getItem('username');
        
        const response = await fetch('http://localhost:9090/ai/chat', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            userId,
            username,
            resumeVersion: this.resumeVersion,
            formData: this.form
          })
        });

        if (!response.ok) {
          throw new Error('网络请求失败');
        }

        const result = await response.json();
        
        if (!result.success) {
          throw new Error(result.error || '生成失败');
        }

        // 存储简历数据
        localStorage.setItem('resumeData', JSON.stringify(result.content));
        
        // 显示成功状态
        this.statusText = '简历生成成功！';
        
        // 延迟关闭对话框并跳转
        setTimeout(() => {
          this.showResumeModal = false;
          this.showGeneratingDialog = false;
          this.$router.push('/resume');
        }, 1000);

      } catch (error) {
        console.error('生成简历失败:', error);
        this.statusText = '生成失败: ' + error.message;
        this.$message.error(error.message);
      } finally {
        this.generating = false;
      }
    },

    // 解析AI返回的内容
    parseResumeContent(content) {
      // 初始化简历数据结构
      const resumeData = {
        name: content.name || '',
        phone: content.phone || '',
        email: content.email || '',
        jobStatus: content.jobStatus || '',
        jobTitle: content.jobTitle || '',
        salaryExpectation: content.salaryExpectation || '',
        education: {
          school: '',
          major: '',
          degree: '',
          studyPeriod: []
        },
        profession: {
          skill: ''
        },
        work: {
          company: '',
          department: '',
          position: '',
          period: [],
          details: ''
        },
        project: {
          name: '',
          period: [],
          details: ''
        },
        award: {
          details: ''
        }
      };

      // 如果是对象格式的响应，直接使用
      if (typeof content === 'object') {
        if (content.education) resumeData.education = { ...resumeData.education, ...content.education };
        if (content.profession) resumeData.profession = { ...resumeData.profession, ...content.profession };
        if (content.work) resumeData.work = { ...resumeData.work, ...content.work };
        if (content.project) resumeData.project = { ...resumeData.project, ...content.project };
        if (content.award) resumeData.award = { ...resumeData.award, ...content.award };
        return resumeData;
      }

      // 如果是字符串格式，按原有逻辑解析
      const sections = content.split('\n\n');
      sections.forEach(section => {
        if (section.includes('求职意向')) {
          const lines = section.split('\n');
          lines.forEach(line => {
            if (line.includes('职位')) resumeData.jobTitle = line.split('：')[1];
            if (line.includes('薪资')) resumeData.salaryExpectation = line.split('：')[1];
          });
        } else if (section.includes('教育经历')) {
          const lines = section.split('\n');
          lines.forEach(line => {
            if (line.includes('学校')) resumeData.education.school = line.split('：')[1];
            if (line.includes('专业')) resumeData.education.major = line.split('：')[1];
            if (line.includes('学历')) resumeData.education.degree = line.split('：')[1];
          });
        } else if (section.includes('专业技能')) {
          resumeData.profession.skill = section.split('\n').slice(1).join('\n');
        } else if (section.includes('工作经历')) {
          const lines = section.split('\n');
          lines.forEach(line => {
            if (line.includes('公司')) resumeData.work.company = line.split('：')[1];
            if (line.includes('职位')) resumeData.work.position = line.split('：')[1];
            if (line.includes('工作内容')) resumeData.work.details = line.split('：')[1];
          });
        } else if (section.includes('项目经历')) {
          resumeData.project.details = section.split('\n').slice(1).join('\n');
        } else if (section.includes('获奖情况')) {
          resumeData.award.details = section.split('\n').slice(1).join('\n');
        }
      });

      return resumeData;
    }
  },
};
</script>

<style scoped>
.header-container {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 20px;
  background: #bcc0e7; /* 修改为更柔和的深色背景 */
  color: #ecf0f1; /* 调整文字颜色 */
  height: 40px; /* 固定高度 */
}
.header-nav {
  display: flex;
  align-items: center;
  width: 100%;
  gap: 20px; /* 增加元素间距 */
  min-height: 40px; /* 新增最小高度 */
}

.header-left {
  display: flex;
  align-items: center;
  gap: 15px; /* 欢迎信息与导航按钮间距 */
  flex-grow: 1; /* 左侧自适应宽度 */
}

.welcome-text {
  font-size: 18px;
  font-weight: 500;
}

.nav-button {
  padding: 8px 12px !important; /* 调整按钮大小 */
  border-radius: 4px; /* 圆角按钮 */
  transition: all 0.3s; /* 添加过渡效果 */
  height: 32px; /* 统一按钮高度 */
}

.nav-button:hover {
  background: rgba(255, 255, 255, 0.05); /* 悬停效果 */
}

.header-right {
  display: flex;
  align-items: center;
  gap: 15px;
  min-height: 40px; /* 新增最小高度 */
}

.action-button {
  padding: 8px 15px !important;
  border-radius: 20px;
}

.logout-button {
  padding: 8px 15px !important;
  border-radius: 4px; /* 移除圆形样式 */
  box-shadow: 0 2px 4px rgba(255, 69, 89, 0.3); /* 添加微阴影 */
}

.version-select {
  margin-bottom: 20px;
  text-align: center;
}
.resume-form {
  margin-top: 10px;
}

/* 新增响应式调整 */
@media (max-width: 768px) {
  .header-container {
    padding: 0 10px;
  }

  .nav-button {
    padding: 6px 10px !important;
  }
}

.generating-status {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 20px;
  padding: 20px;
}

.status-text {
  margin: 0;
  text-align: center;
  color: #606266;
  font-size: 16px;
}

.dialog-footer {
  width: 100%;
  display: flex;
  justify-content: center;
}

/* 添加过渡效果 */
.el-dialog {
  transition: all 0.3s ease-in-out;
}

.el-progress {
  transition: all 0.5s ease-in-out;
}

/* 添加加载动画样式 */
:deep(.el-progress-circle) {
  width: 120px !important;
  height: 120px !important;
}

:deep(.el-progress__text) {
  display: none;
}

:deep(.el-progress-circle__track) {
  stroke: #e5e9f2;
}

:deep(.el-progress-circle__path) {
  stroke: #409EFF;
  animation: loading-rotate 2s linear infinite;
}

@keyframes loading-rotate {
  100% {
    transform: rotate(360deg);
  }
}
</style>
