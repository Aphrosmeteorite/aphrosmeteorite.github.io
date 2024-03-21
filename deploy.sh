# 用于部署博客的脚本
hugo -F --cleanDestinationDir
# 文件夹的内容推送到远程仓库
git add .
git commit -m "rebuilding site $(date)"
# 拉取远程仓库的更新
git pull --rebase origin main
git push -u origin main