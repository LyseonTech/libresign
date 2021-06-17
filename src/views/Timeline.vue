<template>
	<div class="container-timeline">
		<ul>
			<File
				v-for="file in files"
				:key="file.uuid"
				class="file-details"
				:status="file.status"
				:file="file"
				@sidebar="setSidebar" />
		</ul>
		<Sidebar v-if="sidebar"
			ref="sidebar"
			@sign:document="signDocument"
			@closeSidebar="closeSidebar" />
	</div>
</template>

<script>
import axios from '@nextcloud/axios'
import { generateUrl } from '@nextcloud/router'
import File from '../Components/File'
import Sidebar from '../Components/File/Sidebar.vue'
import { showError, showSuccess } from '@nextcloud/dialogs'

export default {
	name: 'Timeline',
	components: {
		File,
		Sidebar,
	},
	data() {
		return {
			sidebar: false,
			files: [],
		}
	},

	created() {
		this.getData()
	},

	methods: {
		async getData() {
			try {

				const response = await axios.get(generateUrl('/apps/libresign/api/0.1/file/list'))
				this.files = response.data.data
			} catch (err) {
				showError('An error occurred while fetching the files')
			}
		},
		openSidebar() {
			this.sidebar = true
		},
		setSidebar(objectFile) {
			this.closeSidebar()

			this.$store.commit('setCurrentFile', objectFile)
			this.openSidebar()
		},
		closeSidebar() {
			this.sidebar = false
		},
		async signDocument(param) {
			try {
				const response = await axios.post(generateUrl(`/apps/libresign/api/0.1/sign/file_id/${param.fileId}`), {
					password: param.password,
				})
				if (response.data.action === 350) {
					this.$refs.sidebar.changeTab('signatures')
				}
				this.$refs.sidebar.clearSignInput()
				this.disabledSign = true
				return showSuccess(response.data.message)
			} catch (err) {
				if (err.response.data.action === 400) {
					window.location.href = generateUrl('/apps/libresign/reset-password?redirect=CreatePassword')
				}
				err.response.data.errors.map(
					error => {
						showError(error)
					}
				)
			}

		},
	},
}
</script>
<style lang="scss" scoped>
.container-timeline{
	display: flex;
	width: 100%;
	flex-direction: row;

	ul{
		display: flex;
		width: 100%;
		flex-wrap: wrap;
	}

	.file-details:hover {
		background: darken(#fff, 10%);
		border-radius: 10px;
	}
}
</style>